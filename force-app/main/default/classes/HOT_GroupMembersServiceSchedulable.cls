public without sharing class HOT_GroupMembersServiceSchedulable implements Schedulable {

    public void execute(SchedulableContext sc) {
		Map<String, List<String>> inputParameters = new Map<String, List<String>>();
		inputParameters.put('formidler', new List<String>{'HOT_Tolk_Formidler_Gruppe', 'HOT', 'formidler'});
		inputParameters.put('tolk', new List<String>{'HOT_Tolk_Ansatt_Gruppe', 'HOT', 'tolk'});
		inputParameters.put('leder', new List<String>{'HOT_Tolk_Leder_Gruppe', 'HOT', 'leder'});
		for(String role : inputParameters.keyset()){
			HOT_GroupMembersService.updateGroupMembers(inputParameters.get(role)[0], inputParameters.get(role)[1], inputParameters.get(role)[2]);
		}
    }
}
