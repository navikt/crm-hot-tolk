public class HOT_ReleaseToFreelanceFlowController {
	
	public String getRecordId() {
        return ApexPages.CurrentPage().getparameters().get('id');
	}
	
}