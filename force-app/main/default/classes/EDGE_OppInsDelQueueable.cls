/*
* @Name: EDGE_ActivityTLInsDelQueueable
* @Req: This is Queueable class for inserting and deleting ActivityTargetList

* @History                                                            
                                                            
* @VERSION     AUTHOR            DATE              DETAIL
	v1.0     Rajarshi Lahiri   31/01/2023         
	
*/


public class EDGE_OppInsDelQueueable implements Queueable {
 	
    Map<String,List<Opportunity>> mapOps;
    
    public EDGE_OppInsDelQueueable(Map<String,List<Opportunity>> mapOps){
        this.mapOps = mapOps;
    }

    public void execute(QueueableContext context) {
        
       if(mapOps.containskey('Insert') && mapOps.get('Insert')!=Null && mapOps.get('Insert').size()>0)
        {
            Database.insert(mapOps.get('Insert'));
        }
        if(mapOps.containskey('Delete') && mapOps.get('Delete')!=Null && mapOps.get('Delete').size()>0) 
        {
            Map<String,List<Opportunity>> atlMap=new Map<String,List<Opportunity>>();
            atlMap.put('Deletion Queued',mapOps.get('Delete'));
            if(!Test.isRunningTest()){
            	System.enqueueJob(new EDGE_OppInsDelQueueable(atlMap));
            }
        }
        if(mapOps.containskey('Deletion Queued') && mapOps.get('Deletion Queued')!=Null && mapOps.get('Deletion Queued').size()>0) {
            Database.delete(mapOps.get('Deletion Queued'));
        }
	}
}