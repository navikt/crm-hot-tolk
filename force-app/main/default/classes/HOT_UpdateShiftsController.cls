public with sharing class HOT_UpdateShiftsController {
    @AuraEnabled(cacheable=true)
    public static List<Shift> getShifts(Id recordId) {
        Shift shift = [SELECT Id, ServiceResourceId, StartTime FROM Shift WHERE Id = :recordId];
        List<Shift> shifts = [
            SELECT Id, ServiceResourceId, StartTime, EndTime, Label, ShiftNumber, CreatedDate
            FROM Shift
            WHERE ServiceResourceId = :shift.ServiceResourceId AND StartTime >= :shift.StartTime
            ORDER BY StartTime ASC
        ];
        return shifts;
    }

    @AuraEnabled
    public static void updateRecords(List<Shift> records, Map<String, String> fieldValues) {
        for (Shift shift : records) {
            for (String key : fieldValues.keySet()) {
                if (key.contains('Time')) {
                    List<String> hours_minutes = fieldValues.get(key).split(':');
                    shift.put(
                        key,
                        Datetime.newInstance(
                            ((Datetime) shift.get(key)).date(),
                            Time.newInstance(Integer.valueOf(hours_minutes[0]), Integer.valueOf(hours_minutes[1]), 0, 0)
                        )
                    );
                } else {
                    shift.put(key, fieldValues.get(key));
                }
            }
        }
        update records;
    }
    @AuraEnabled
    public static void deleteRecords(List<Shift> records) {
        delete records;
    }
}
