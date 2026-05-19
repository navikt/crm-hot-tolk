@IsTest
public with sharing class FSL_TestStub implements Callable {
    public FSL_TestStub() {
    }
    public Object call(String action, Map<String, Object> args) {
        /**
         * FSL.GlobalAPIS call shoild be UNCOMMENTED in Sandbox or enviroment where FSL is installed,
         * and should be used to add status transition in order to test the code
         * that relies on status transitions. In production orgs where FSL is not available,
         * this code will not be executed because of the check for the existence of FSL.GlobalAPIS class in the test
         */

        if (action == 'addStatusTransition') {
            String fromStatus = (String) args.get('fromStatus');
            String toStatus = (String) args.get('toStatus');
            // FSL.GlobalAPIS.addStatusTransition(fromStatus, toStatus);
        }
        return null;
    }
}
