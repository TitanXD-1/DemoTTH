public class EDGE_TerrHierarchyAsyncUpdate implements Queueable{
    private List<Territory_Hierarchy__c> terHierarchyToUpdate;

    public EDGE_TerrHierarchyAsyncUpdate(List<Territory_Hierarchy__c> terHierarchyToUpdate) {
        this.terHierarchyToUpdate = terHierarchyToUpdate;
    }
    
    public void execute(QueueableContext context) {       
        if(terHierarchyToUpdate!=null && terHierarchyToUpdate.size()>0 && Schema.sObjectType.Territory_Hierarchy__c.isUpdateable()){
            update terHierarchyToUpdate;
        }
        
        
    }
    

}