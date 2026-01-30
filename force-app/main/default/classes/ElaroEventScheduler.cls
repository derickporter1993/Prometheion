/**
 * ElaroEventScheduler
 * 
 * Schedulable class to run batch event loading on a schedule
 * 
 * @author Elaro
 * @version 1.0
 */
public with sharing class ElaroEventScheduler implements Schedulable {
    
    private String eventType;
    private Integer daysBack;
    private String framework;
    
    public ElaroEventScheduler(String eventType, Integer daysBack, String framework) {
        this.eventType = eventType;
        this.daysBack = daysBack != null ? daysBack : 7;
        this.framework = framework != null ? framework : ElaroConstants.FRAMEWORK_SOC2;
    }
    
    public ElaroEventScheduler() {
        this('LOGIN', 7, ElaroConstants.FRAMEWORK_SOC2);
    }
    
    public void execute(SchedulableContext ctx) {
        Date endDate = Date.today();
        Date startDate = endDate.addDays(-this.daysBack);
        
        ElaroEventMonitoringService.startBatchEventLoad(
            this.eventType,
            startDate,
            endDate,
            this.framework
        );
    }
}
