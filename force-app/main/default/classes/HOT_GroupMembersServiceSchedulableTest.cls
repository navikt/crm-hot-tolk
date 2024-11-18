@IsTest
public with sharing class HOT_GroupMembersServiceSchedulableTest {
    @testSetup
    public static void setup() {
        if (
            [
                SELECT DeveloperName
                FROM PermissionSetGroup
                WHERE
                    Developername = 'HOT_Tolk_Formidler_Gruppe'
                    OR DeveloperName = 'HOT_Tolk_Ansatt_Gruppe'
                    OR DeveloperName = 'HOT_Tolk_Leder_Gruppe'
            ]
            .size() != 3
        ) {
            PermissionSetGroup formidlerPermsetGroup = new PermissionSetGroup(
                DeveloperName = 'HOT_Tolk_Formidler_Gruppe',
                MasterLabel = 'HOT_Tolk_Formidler_Gruppe'
            );
            PermissionSetGroup tolkPermsetGroup = new PermissionSetGroup(
                DeveloperName = 'HOT_Tolk_Ansatt_Gruppe',
                MasterLabel = 'HOT_Tolk_Ansatt_Gruppe'
            );
            PermissionSetGroup lederPermsetGroup = new PermissionSetGroup(
                DeveloperName = 'HOT_Tolk_Leder_Gruppe',
                MasterLabel = 'HOT_Tolk_Leder_Gruppe'
            );
            insert new List<PermissionSetGroup>{ formidlerPermsetGroup, tolkPermsetGroup, lederPermsetGroup };
        }
    }

    private static String CRON_EXP = '0 0 0 3 9 ? 2099';

    @IsTest
    private static void execute() {
        Test.startTest();
        String jobId = System.schedule(
            'HOT_GroupMembersServiceSchedulable',
            CRON_EXP,
            new HOT_GroupMembersServiceSchedulable()
        );
        Test.stopTest();
        System.assert(jobId != null);
    }
}
