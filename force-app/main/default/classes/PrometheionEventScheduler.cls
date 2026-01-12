/**
 * PrometheionEventScheduler
 * 
 * Schedulable class to run batch event loading on a schedule
 * 
 * @author Prometheion
 * @version 1.0
 */
public with sharing class PrometheionEventScheduler implements Schedulable {
    
    private String eventType;
    private Integer daysBack;
    private String framework;
    
    public PrometheionEventScheduler(String eventType, Integer daysBack, String framework) {
        this.eventType = eventType;
        this.daysBack = daysBack != null ? daysBack : 7;
        this.framework = framework != null ? framework : PrometheionConstants.FRAMEWORK_SOC2;
    }
    
    public PrometheionEventScheduler() {
        this('LOGIN', 7, PrometheionConstants.FRAMEWORK_SOC2);
    }
    
    public void execute(SchedulableContext ctx) {
        Date endDate = Date.today();
        Date startDate = endDate.addDays(-this.daysBack);
        
        PrometheionEventMonitoringService.startBatchEventLoad(
            this.eventType,
            startDate,
            endDate,
            this.framework
        );
    }
}
