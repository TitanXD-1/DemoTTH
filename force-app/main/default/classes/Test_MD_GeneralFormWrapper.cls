@isTest
public class Test_MD_GeneralFormWrapper {
    
    @testSetup static void setup() {
        DiageoCMS.MockupFactory.generateAcceleratorSetting();
		List<DiageoCMS__Cluster__c> globalClusters = DiageoCMS.MockupFactory.createCluster('GlobalClusterTest', null, 1, 'ClusterRoot', 'GlobalClusterTest');
        List<DiageoCMS__Cluster__c> leafClusters = DiageoCMS.MockupFactory.createCluster('Spain', globalClusters.get(0).Id, 1, 'ClusterLeaf', 'ES');  
        leafClusters[0].Name='Spain';
        leafClusters[0].DiageoCMS__ExternalId__c='ES';
        update leafClusters;
       
        DiageoCMS__Form__c form = new DiageoCMS__Form__c(name='TestForm', DiageoCMS__ExternalID__c='TestForm', DiageoCMS__RetrievalClass__c='testRetrieval',DiageoCMS__SaveClass__c='testSaveClass', DiageoCMS__Status__c='Active', DiageoCMS__Cluster__c = leafClusters.get(0).Id);
        insert form;
        DiageoCMS__FormSection__c formSection = new DiageoCMS__FormSection__c(name='testSection', DiageoCMS__SectionTitle__c='testSection', DiageoCMS__ExternalID__c='testSection', DiageoCMS__Form__c=form.id);
        insert formSection;
        DiageoCMS__FormValidation__c formValidation = new DiageoCMS__FormValidation__c(name='testVal', DiageoCMS__errormessage__c= '');
        insert formValidation;
        DiageoCMS__FormElement__c formField = new DiageoCMS__FormElement__c(DiageoCMS__formvalidation__c = formValidation.id, name='testField', DiageoCMS__ExternalID__c='testField', DiageoCMS__FieldAPIName__c='Name', DiageoCMS__FieldLabel__c='testField', DiageoCMS__FieldType__c='Text', DiageoCMS__FormSection__c=formSection.id, DiageoCMS__Status__c='Active',
                                                                            DiageoCMS__HelpText__c='testField', DiageoCMS__ObjectAPIName__c='Account');
        DiageoCMS__FormElement__c formField2 = new DiageoCMS__FormElement__c(DiageoCMS__formvalidation__c = formValidation.id, name='testField2', DiageoCMS__ExternalID__c='testField2', DiageoCMS__FieldAPIName__c='lastModifiedDate', DiageoCMS__FieldLabel__c='testField', DiageoCMS__FieldType__c='Text', DiageoCMS__FormSection__c=formSection.id, DiageoCMS__Status__c='Active',
                                                                             DiageoCMS__HelpText__c='testField', DiageoCMS__ObjectAPIName__c='Account');
        insert new List<DiageoCMS__FormElement__c>{formField, formField2};
    }
    
     static testMethod void getFormSettings(){
         List<MD_FormRegistrationController.ClusterWrapper> ClusterData = MD_FormRegistrationController.getClusterData();
         DiageoCMS.GeneralForm form2 = new DiageoCMS.GeneralForm('TestForm', new Set<Id>{ClusterData[0].ClusterId}); 
         MD_GeneralFormWrapper.FormSettings form3 = new  MD_GeneralFormWrapper.FormSettings(form2.FormSettings);
     }
	
}