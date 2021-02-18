public class HOT_ReleaseToFreelanceFlowController {
    public static String getRecordId() {
        return ApexPages.CurrentPage().getparameters().get('id');
    }
}
