public with sharing class FlowBenchmarkService {
    public class BenchmarkStats {
        @AuraEnabled
        public Decimal percentile50; // Median
        @AuraEnabled
        public Decimal percentile90; // 90th percentile
        @AuraEnabled
        public Decimal percentile99; // 99th percentile (problem threshold)
        @AuraEnabled
        public Decimal average;
        @AuraEnabled
        public Decimal min;
        @AuraEnabled
        public Decimal max;
        @AuraEnabled
        public Integer sampleSize;
    }

    public class PerformanceRating {
        @AuraEnabled
        public String rating; // 'Excellent', 'Good', 'Slow', 'Critical'
        @AuraEnabled
        public String trend; // 'Improving', 'Stable', 'Degrading'
        @AuraEnabled
        public String message;
        @AuraEnabled
        public Decimal percentileRank; // Where this execution falls (0-100)
        @AuraEnabled
        public BenchmarkStats benchmarks;
    }

    /**
     * Calculate benchmark statistics for a specific Flow
     */
    @AuraEnabled(cacheable=true)
    public static BenchmarkStats getFlowBenchmarks(String flowName, Integer daysBack) {
        Datetime startDate = System.now().addDays(-Math.abs(daysBack));

        List<Flow_Execution__c> executions = [
            SELECT CPU__c
            FROM Flow_Execution__c
            WHERE Flow_Name__c = :flowName AND CreatedDate >= :startDate AND CPU__c != NULL
            ORDER BY CPU__c ASC
        ];

        if (executions.isEmpty()) {
            BenchmarkStats emptyStats = new BenchmarkStats();
            emptyStats.sampleSize = 0;
            return emptyStats;
        }

        BenchmarkStats stats = new BenchmarkStats();
        stats.sampleSize = executions.size();

        // Calculate percentiles
        stats.percentile50 = calculatePercentile(executions, 50);
        stats.percentile90 = calculatePercentile(executions, 90);
        stats.percentile99 = calculatePercentile(executions, 99);

        // Calculate min, max, average
        stats.min = executions[0].CPU__c;
        stats.max = executions[executions.size() - 1].CPU__c;

        Decimal total = 0;
        for (Flow_Execution__c exec : executions) {
            total += exec.CPU__c;
        }
        stats.average = total / executions.size();

        return stats;
    }

    /**
     * Rate a specific Flow execution performance
     */
    @AuraEnabled
    public static PerformanceRating rateFlowExecution(
        String flowName,
        Decimal cpuTime,
        Integer daysBack
    ) {
        PerformanceRating rating = new PerformanceRating();
        rating.benchmarks = getFlowBenchmarks(flowName, daysBack);

        if (rating.benchmarks == null || rating.benchmarks.sampleSize < 10) {
            rating.rating = 'Unknown';
            rating.message =
                'Not enough historical data for benchmarking (need at least 10 executions)';
            rating.trend = 'Unknown';
            rating.percentileRank = null;
            return rating;
        }

        // Calculate percentile rank
        rating.percentileRank = calculatePercentileRank(
            cpuTime,
            flowName,
            System.now().addDays(-Math.abs(daysBack))
        );

        // Determine rating based on where it falls
        if (cpuTime <= rating.benchmarks.percentile50) {
            rating.rating = 'Excellent';
            rating.message = 'Faster than 50% of executions';
        } else if (cpuTime <= rating.benchmarks.percentile90) {
            rating.rating = 'Good';
            rating.message = 'Within normal range';
        } else if (cpuTime <= rating.benchmarks.percentile99) {
            rating.rating = 'Slow';
            rating.message = 'Slower than 90% of executions - investigate';
        } else {
            rating.rating = 'Critical';
            rating.message = 'In the slowest 1% - immediate attention needed';
        }

        // Calculate trend
        rating.trend = calculateFlowTrend(flowName, daysBack);

        return rating;
    }

    /**
     * Get performance rating for recent executions of a Flow
     */
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getRecentExecutionsWithRatings(
        String flowName,
        Integer limitSize,
        Integer daysBack
    ) {
        Datetime startDate = System.now().addDays(-Math.abs(daysBack));
        BenchmarkStats benchmarks = getFlowBenchmarks(flowName, daysBack);

        List<Flow_Execution__c> executions = [
            SELECT
                Id,
                Flow_Name__c,
                CPU__c,
                SOQL__c,
                DML__c,
                Status__c,
                Run_Time__c,
                CreatedDate
            FROM Flow_Execution__c
            WHERE Flow_Name__c = :flowName AND CreatedDate >= :startDate
            ORDER BY CreatedDate DESC
            LIMIT :Math.max(1, limitSize)
        ];

        List<Map<String, Object>> results = new List<Map<String, Object>>();

        for (Flow_Execution__c exec : executions) {
            Map<String, Object> record = new Map<String, Object>();
            record.put('execution', exec);

            if (benchmarks != null && exec.CPU__c != null) {
                String execRating = getRating(exec.CPU__c, benchmarks);
                record.put('rating', execRating);
                record.put('percentileRank', calculatePercentileRank(exec.CPU__c, flowName, startDate));
            } else {
                record.put('rating', 'Unknown');
                record.put('percentileRank', null);
            }

            results.add(record);
        }

        return results;
    }

    // Private helper methods

    private static Decimal calculatePercentile(List<Flow_Execution__c> sortedList, Integer percentile) {
        if (sortedList.isEmpty()) {
            return null;
        }

        Integer index = (Integer) Math.floor(
            (Decimal.valueOf(percentile) / 100) * sortedList.size()
        );
        index = Math.min(index, sortedList.size() - 1);
        index = Math.max(index, 0);

        return sortedList[index].CPU__c;
    }

    private static Decimal calculatePercentileRank(
        Decimal value,
        String flowName,
        Datetime startDate
    ) {
        // Count how many executions were slower
        Integer totalCount = [
            SELECT COUNT()
            FROM Flow_Execution__c
            WHERE Flow_Name__c = :flowName AND CreatedDate >= :startDate AND CPU__c != NULL
        ];

        if (totalCount == 0) {
            return null;
        }

        Integer slowerCount = [
            SELECT COUNT()
            FROM Flow_Execution__c
            WHERE
                Flow_Name__c = :flowName
                AND CreatedDate >= :startDate
                AND CPU__c > :value
        ];

        return ((Decimal) (totalCount - slowerCount) / totalCount) * 100;
    }

    private static String getRating(Decimal cpuTime, BenchmarkStats benchmarks) {
        if (cpuTime <= benchmarks.percentile50) {
            return 'Excellent';
        } else if (cpuTime <= benchmarks.percentile90) {
            return 'Good';
        } else if (cpuTime <= benchmarks.percentile99) {
            return 'Slow';
        } else {
            return 'Critical';
        }
    }

    private static String calculateFlowTrend(String flowName, Integer daysBack) {
        // Compare first half vs second half of time period
        Datetime startDate = System.now().addDays(-Math.abs(daysBack));
        Datetime midpoint = startDate.addSeconds(
            (Integer) ((System.now().getTime() - startDate.getTime()) / 2000)
        );

        AggregateResult[] firstHalf = [
            SELECT AVG(CPU__c) avgCpu
            FROM Flow_Execution__c
            WHERE
                Flow_Name__c = :flowName
                AND CreatedDate >= :startDate
                AND CreatedDate < :midpoint
                AND CPU__c != NULL
        ];

        AggregateResult[] secondHalf = [
            SELECT AVG(CPU__c) avgCpu
            FROM Flow_Execution__c
            WHERE Flow_Name__c = :flowName AND CreatedDate >= :midpoint AND CPU__c != NULL
        ];

        if (firstHalf.isEmpty() || secondHalf.isEmpty()) {
            return 'Stable';
        }

        Decimal firstAvg = (Decimal) firstHalf[0].get('avgCpu');
        Decimal secondAvg = (Decimal) secondHalf[0].get('avgCpu');

        if (firstAvg == null || secondAvg == null) {
            return 'Stable';
        }

        Decimal change = ((secondAvg - firstAvg) / firstAvg) * 100;

        if (change < -10) {
            return 'Improving';
        } else if (change > 10) {
            return 'Degrading';
        } else {
            return 'Stable';
        }
    }
}
