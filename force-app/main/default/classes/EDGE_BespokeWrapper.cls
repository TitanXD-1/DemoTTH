/**********************************************************************
Name: EDGE_BriefcaseWrapper
=======================================================================
History                                                            
-------                                                            
VERSION     AUTHOR                  DATE              DETAIL
1.0         Preyanka Ghosh			03/12/2019		  ES20-6298 
***********************************************************************/

global inherited sharing class EDGE_BespokeWrapper{
    public String bespokeId {get;set;}
    public String bespokeName {get;set;}
    public String outletId {get;set;}
    public String deliveryPartnerId {get;set;}
    public String bespokeStatus {get;set;}
    public DateTime lastModifiedDate {get;set;}
    public String recordTypeId {get;set;}
    public Decimal bespokeBudget {get;set;}
    public String bespokeContractId {get;set;}
    public String customerContactEmail {get;set;}
    public String customerContactPhone {get;set;}
    public String customerPreferredContact {get;set;}
    public String diageoContact {get;set;}
    public String diageoContactEmail {get;set;}
    public String diageoContactPhoneNumber {get; set;}
    public Date bespokeEndDate {get; set;}
    public Date bespokeStartDate {get; set;}
    public Decimal incrementalNSV {get; set;}
    public Decimal incrementalVolume {get; set;}
    public Decimal bespokeROI {get;set;}   
    public String bespokeProjectName {get;set;}
    public DateTime createdDate {get;set;}
    public String segmentActivation {get;set;}
    public String activityObjectives {get;set;}
    public String productFocus {get;set;}
    public Date siteVisitDate {get;set;}
    public Time siteVisitTime {get;set;}
    public String venueNotes {get;set;}
    public Date bumpIn {get;set;}
    public Date bumpOut {get;set;}
    public string userId {get;set;}
}