public with sharing class HandlerFieldHistoryTrack 
{
    DynamicTriggerGeneration objDynamicTriggerGenerationHandler = new DynamicTriggerGeneration ();
    public void createDynamicTrigger(list<FieldHistoryTrackingSetting__c> lstFHT,string sessionId){   
       if(lstFHT != null && lstFHT.size()>0){
            for(FieldHistoryTrackingSetting__c fls : lstFHT){ 
                if(fls.objectName__c != null){                  
                    string sobjname = fls.objectName__c;
                    string sobjectLabel=fls.Object_Label__c;
                    String selectedFields=fls.selectedFields__c;
                    DynamicTriggerGeneration.webservicemethodofcreateDynamicTrigger(sobjname,sobjectLabel,selectedFields,sessionId);                    
                } 
    
            }
      }
   }
   public  void changeFHTDataHolderSetting(list<FieldHistoryTrackingSetting__c> lstFHT)
   {
        set<string> setSobjects=new set<string>();
        List<FHTDataHolder__c> LstToUpdate=new List<FHTDataHolder__c> ();
        set<String> setSeletedFields;
        for(FieldHistoryTrackingSetting__c obj: lstFHT)
        {
            setSobjects.add(obj.objectName__c);
        }
        List<FHTDataHolder__c> lstFHTData= [SELECT 
                                            Field_Name__c,
                                            Object_Name__c,
                                            FieldDataTrack__c,
                                            IsFieldCurrentlySelected__c,
                                            IsObectCurrentlySelected__c
                                            FROM FHTDataHolder__c
                                            WHERE Object_Name__c IN:setSobjects];
                                  
        
        for(FieldHistoryTrackingSetting__c obj:lstFHT)             //to iterate over trigger.new
        {
            setSeletedFields=new set<String>();
            if(obj.selectedFields__c !=null){
            List<string> lstSelectedFields=obj.selectedFields__c.split(',');
            //setSeletedFields= new set<String>(lstSelectedFields); 
            for(string field:lstSelectedFields)
            {
                setSeletedFields.add(field);
            }
            system.debug('SET of Selected Fields ='+setSeletedFields);
            }
            if(lstFHTData.size()>0)  
            {
                for(FHTDataHolder__c FHT:lstFHTData)           
                {
                    if(setSeletedFields.contains(FHT.Field_Name__c) && obj.objectName__c==FHT.Object_Name__c && !FHT.IsFieldCurrentlySelected__c)
                    {
                        FHT.IsFieldCurrentlySelected__c=true;
                        FHT.IsObectCurrentlySelected__c=obj.isSelected__c;
                        LstToUpdate.add(FHT);
                    }
                    else if(!setSeletedFields.contains(FHT.Field_Name__c) && obj.objectName__c==FHT.Object_Name__c && FHT.IsFieldCurrentlySelected__c)
                    {
                        FHT.IsFieldCurrentlySelected__c=false;
                        FHT.IsObectCurrentlySelected__c=obj.isSelected__c;
                        LstToUpdate.add(FHT);
                    }
                    else if(setSeletedFields.size()==0 && obj.objectName__c==FHT.Object_Name__c)
                    {
                        FHT.IsFieldCurrentlySelected__c=false;
                        FHT.IsObectCurrentlySelected__c=false;
                        LstToUpdate.add(FHT);
                    }
                }
            }
        }
        try{
        update LstToUpdate;
        }
        catch(DMLException e)
        {
        
        }
   }
}