public class CaseTriggerHandler 
{
	//sample comment 
	static final Map<ID,Schema.RecordTypeInfo> caseRecTypeInfoById = Schema.SObjectType.Case.getRecordTypeInfosById();
	
	public CaseTriggerHandler()
	{
		
	}   
	
	public static void updateRestrictedAndContactOnExposure(List<Case> newCases)
	{
		Map<ID,List<Case>> exposuresByParentCaseId = new Map<ID,List<Case>>();
		
		for(Case c : newCases)
		{
			if(caseRecTypeInfoById.get(c.RecordTypeId).getName() == Constant.AB_EXPOSURE)
				c.Restricted__c = true;
			if(caseRecTypeInfoById.get(c.RecordTypeId).getName() == Constant.AB_EXPOSURE || caseRecTypeInfoById.get(c.RecordTypeId).getName() == Constant.BASE_EXPOSURE)
			{
				if(exposuresByParentCaseId.containsKey(c.ParentId))
					exposuresByParentCaseId.get(c.ParentId).add(c);
				else
					exposuresByParentCaseId.put(c.ParentId,new List<Case>{c});
			}
		}
		
		List<Case> claims = [Select Id, ContactId From Case Where Id IN: exposuresByParentCaseId.keySet()];
		for(Case claim : claims)
		{
			List<Case> exposures = exposuresByParentCaseId.get(claim.Id);
			for(Case exp : exposures)
				exp.ContactId = claim.ContactId;
		}
	}
	
	
	
	public static void createCaseProxy(List<Case> newCases)
	{
		system.debug('IN CREATE PROXY');
		List<Exposure__c> expToCreate = new List<Exposure__c>();
		for(Case c : newCases)
		{
			if(caseRecTypeInfoById.get(c.RecordTypeId).getName() == Constant.AB_EXPOSURE || caseRecTypeInfoById.get(c.RecordTypeId).getName() == Constant.BASE_EXPOSURE)
			{
				Exposure__c exp = new Exposure__c();
				exp.Case__c = c.Id;
				exp.Claim__c = c.ParentId;
				exp.OwnerId = c.OwnerId;
				expToCreate.add(exp);
			}
		}
		system.debug('--EXP TO CREATE--' + expToCreate);
		if(!expToCreate.isEmpty())
			insert expToCreate;
	}
	
	public static void deleteCaseProxy(List<Case> oldCases)
	{
		Set<ID> deletedExpIds = new Set<ID>();
		for(Case c : oldCases)
		{
			if(caseRecTypeInfoById.get(c.RecordTypeId).getName() == Constant.AB_EXPOSURE || caseRecTypeInfoById.get(c.RecordTypeId).getName() == Constant.BASE_EXPOSURE)
				deletedExpIds.add(c.Id);
		}
		
		if(!deletedExpIds.IsEmpty())
		{
			List<Exposure__c> expTodelete = [Select Id , Case__c from Exposure__c Where Case__c IN: deletedExpIds];
			delete expTodelete;
		}
	}
}