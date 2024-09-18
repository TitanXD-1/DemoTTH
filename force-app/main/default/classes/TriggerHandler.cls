/**********************************************************************
	Name: TriggerHandler Class
=======================================================================
    Purpose: 
=======================================================================
    History                                                            
    -------                                                            
    VERSION   AUTHOR            DATE              DETAIL
       1.0    Kapil Baliyan     06/02/2019      Initial Development
***********************************************************************/
public interface TriggerHandler {
    
    void beforeInsert(List<SObject> newItems);
    void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems);
    void beforeDelete(Map<Id, SObject> oldItems);
    void afterInsert(Map<Id, SObject> newItems);
    void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems);
    void afterDelete(Map<Id, SObject> oldItems);
    void afterUndelete(Map<Id, SObject> oldItems);
    Boolean isDisabled();
}