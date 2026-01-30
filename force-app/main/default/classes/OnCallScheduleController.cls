/**
 * @description Controller for On-Call Schedule LWC component
 * Provides CRUD operations for Elaro_On_Call_Schedule__c records
 *
 * @author Elaro Development Team
 * @since 2026-01
 */
public with sharing class OnCallScheduleController {

    /**
     * @description Gets all on-call schedules ordered by start time
     * @return List of schedule records with related user info
     */
    @AuraEnabled(cacheable=true)
    public static List<Elaro_On_Call_Schedule__c> getSchedules() {
        return [
            SELECT Id, Name, User__c, User__r.Name, User__r.Email,
                   Rotation_Name__c, Start_Time__c, End_Time__c,
                   Timezone__c, Notification_Methods__c, Active__c
            FROM Elaro_On_Call_Schedule__c
            WITH USER_MODE
            ORDER BY Start_Time__c DESC
            LIMIT 200
        ];
    }

    /**
     * @description Creates a new on-call schedule
     * @param schedule The schedule record to create
     * @return The created schedule ID
     */
    @AuraEnabled
    public static Id createSchedule(Elaro_On_Call_Schedule__c schedule) {
        validateSchedule(schedule);

        if (Schema.sObjectType.Elaro_On_Call_Schedule__c.isCreateable()) {
            insert schedule;
            return schedule.Id;
        } else {
            throw new AuraHandledException('Insufficient permissions to create schedules');
        }
    }

    /**
     * @description Updates an existing on-call schedule
     * @param schedule The schedule record to update
     */
    @AuraEnabled
    public static void updateSchedule(Elaro_On_Call_Schedule__c schedule) {
        validateSchedule(schedule);

        if (Schema.sObjectType.Elaro_On_Call_Schedule__c.isUpdateable()) {
            update schedule;
        } else {
            throw new AuraHandledException('Insufficient permissions to update schedules');
        }
    }

    /**
     * @description Deletes an on-call schedule
     * @param scheduleId The ID of the schedule to delete
     */
    @AuraEnabled
    public static void deleteSchedule(Id scheduleId) {
        if (Schema.sObjectType.Elaro_On_Call_Schedule__c.isDeletable()) {
            delete [SELECT Id FROM Elaro_On_Call_Schedule__c WHERE Id = :scheduleId WITH USER_MODE];
        } else {
            throw new AuraHandledException('Insufficient permissions to delete schedules');
        }
    }

    /**
     * @description Validates schedule data before save
     * @param schedule The schedule to validate
     */
    private static void validateSchedule(Elaro_On_Call_Schedule__c schedule) {
        if (schedule.Start_Time__c == null) {
            throw new AuraHandledException('Start time is required');
        }
        if (schedule.End_Time__c == null) {
            throw new AuraHandledException('End time is required');
        }
        if (schedule.Start_Time__c >= schedule.End_Time__c) {
            throw new AuraHandledException('End time must be after start time');
        }
        if (schedule.User__c == null) {
            throw new AuraHandledException('User is required');
        }
    }
}
