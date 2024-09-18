/**
Apex Class Name  :  CP_AgreementArchivingControllerTest
Version          :  1.0
Created Date     :  08/08/2019
Release          :  R1
Function         :  Test for class CP_AgreementArchivingController
Modification Log :

* Developer                   Date                    Description   
* Elena Schwarzböck           08/08/2019              Original Version
* Anamika Shukla              30/04/2024              366446 - EDGE_Global: Allow Only Trusted Cross-Org Redirections
*/

@isTest(seeAllData=false)
public class CP_AgreementArchivingControllerTest {
    
    @testSetup 
    public static void setup(){
        //insert new DiageoCMS__CMSSettings__c(DiageoCMS__ClusterFieldForPublicGroups__c = 'DiageoCMS__ExternalId__c', DiageoCMS__SalesforceDomain__c = 'https://edge--edgedev3.lightning.force.com');
        insert new DiageoCMS__CMSSettings__c( 
            DiageoCMS__ClusterFieldForPublicGroups__c = 'DiageoCMS__ExternalId__c',
            DiageoCMS__SalesforceDomain__c = URL.getCurrentRequestUrl().getHost() //366446   
        ); 
    }    
    
    static testMethod void getAgreement() {
        DiageoCMS__Cluster__c cluster = new DiageoCMS__Cluster__c(
            Name = 'NIR', DiageoCMS__ExternalId__c = 'NIR',
            DiageoCMS__PublicGroupRWName__c = 'NIR_RW',
            DiageoCMS__PublicGroupROUpName__c = 'NIR_ROViewUp', 
            DiageoCMS__PublicGroupRODownName__c = 'NIR_ROViewDown',
            CP_AvailableAgreements__c = 'Terms & Conditions;Privacy Policies'
        );
        insert cluster;
        
        CP_Agreement__c agreement = new CP_Agreement__c(Name = 'Test', Cluster__c = cluster.Id, Type__c = 'Terms & Conditions', Portal__c = 'MyDiageo');
        insert agreement;
        
        CP_AgreementArchivingController.getAgreement(agreement.Id);
    }
    
    static testMethod void doArchive() {
        DiageoCMS__Cluster__c cluster = new DiageoCMS__Cluster__c(
            Name = 'NIR', DiageoCMS__ExternalId__c = 'NIR',
            DiageoCMS__PublicGroupRWName__c = 'NIR_RW',
            DiageoCMS__PublicGroupROUpName__c = 'NIR_ROViewUp', 
            DiageoCMS__PublicGroupRODownName__c = 'NIR_ROViewDown',
            CP_AvailableAgreements__c = 'Terms & Conditions;Privacy Policies'
        );
        insert cluster;
        
        CP_Agreement__c agreement = new CP_Agreement__c(Name = 'Test', Cluster__c = cluster.Id, Type__c = 'Terms & Conditions', Portal__c = 'MyDiageo');
        insert agreement;
        
        CP_AgreementArchivingController.doArchive(agreement.Id);
        CP_AgreementArchivingController.doArchive(null);
    }
    
}