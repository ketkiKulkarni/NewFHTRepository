public with sharing class FieldHistorySetupPageController 
{
    public string objects{get;set;}
    public string myCheckBoxName {get;set;}
    public List<fieldWraperClass> wraperClassList{get;set;}
    public set<String>  selectedFieldSet ;
    public set<string> allObjList=new set<string>();
    public string[] RecordData;
    String fieldvalue = '';
    public Boolean isAllSelected{get;set;}
    public integer counter=0;
    public integer list_size { get; set; }
    public integer total_size { get; set; }
    public List<fieldWraperClass> wraperClassListNew;
    public boolean isPrevious = false;
    
    public FieldHistorySetupPageController() {
    }
     
    //Method to get list of all objects .......
    public List<SelectOption> getobjitems() 
    {  
        List<Schema.SObjectType> gd = Schema.getGlobalDescribe().Values();
        List<SelectOption> options = new List<SelectOption>();   
        options.add(new SelectOption('','--None--'));
        for(Schema.SObjectType objType : gd ) {
          if(objType.getDescribe().isQueryable() && objType.getDescribe().isUpdateable()){
            options.add(new SelectOption(objType.getDescribe().getName()+','+objType.getDescribe().getLabel(),objType.getDescribe().getLabel()+'('+objType.getDescribe().getName()+')'));
            }
            allObjList.add(objType.getDescribe().getName());               //all object list
        }
        options.sort();
        return options; 
    }  
    //Method to get all editable fields for selected object.....

    public void getFieldsList()
    {
        if (list_size == null) {
            list_size = 60;
        }
        
        wraperClassListNew = new List<fieldWraperClass>();
        Map<String, Schema.SObjectType> objMap= Schema.getGlobalDescribe();
        list<String> splittedList =  new list<String>();
        Map <String, Schema.SObjectField> allFieldsMap=new Map <String, Schema.SObjectField>();
        if(objects.subStringBefore(',')!=null)
        {
            Schema.SObjectType s = objMap.get(objects.subStringBefore(','));
            Schema.DescribeSObjectResult r = s.getDescribe();  
            allFieldsMap= r.fields.getMap();  
        }
        wraperClassList=new List<fieldWraperClass>();
        List<FieldHistoryTrackingSetting__c> savedFieldsList=[SELECT objectName__c,selectedFields__c,isSelected__c 
                                                              FROM FieldHistoryTrackingSetting__c
                                                              WHERE objectName__c=:objects.subStringBefore(',') limit 1];
        fieldWraperClass wraperObj;
        for (Schema.SObjectField fieldtype:allFieldsMap.values()) {
            if(fieldtype.getDescribe().isUpdateable()) {
               wraperObj = new fieldWraperClass();
               wraperObj.fieldName=fieldtype.getDescribe().getName();
               wraperObj.fieldLabel=fieldtype.getDescribe().getLabel();
                    
               if(savedFieldsList.size()>0 && savedFieldsList[0].selectedFields__c !=null ){
                 splittedList = savedFieldsList[0].selectedFields__c.split(','); 
                    for(String s : splittedList) {
                       if(s == fieldtype.getDescribe().getName()){
                         wraperObj.isSelected = true;
                         break;
                       }
                    } 
               }
               else{
                  wraperObj.isSelected = false;
               }        
               //wraperClassList.add(wraperObj); 
               wraperClassListNew.add(wraperObj);
            }   
        } 
        wraperClassListNew.sort(); 
        total_size = wraperClassListNew.size();       
        if (total_size < list_size) {
            for (Integer i = 0; i < total_size ; i++) {
                wraperClassList.add(wraperClassListNew[i]);
            }
        } else {
            for (Integer i = 0; i < list_size ; i++) {
                wraperClassList.add(wraperClassListNew[i]);
            }
        }
        
        if(wraperClassList.size()!=null) { 
            setSelectAllCheckboxValue(wraperClassList);   //method to set selectAllCheckBox value
        }     
     }
        
     public void SelectedFieldsName () {
          selectedFieldSet=new set<string>();
          if (wraperClassListNew !=null) {
             for(fieldWraperClass wraperObj:wraperClassListNew) {
                if (wraperObj.isSelected==true) {
                   selectedFieldSet.add(wraperObj.fieldName);
                }
             }
          }
         if(!selectedFieldSet.isEmpty()) {
            saveSetting(selectedFieldSet);
         }
         else {
         ApexPages.AddMessage(new ApexPages.Message(ApexPages.severity.ERROR,'You have not selected any field..'));
         
          
         }
        //displayMessage();
     }
     
     public pagereference displayMessage() {
        ApexPages.AddMessage(new ApexPages.Message(ApexPages.severity.Confirm,'Your field history track settings for '+objects.subStringAfter(',')+' have been saved successfully.'));
        return null;
     }
     
     public PageReference refresh() {
        //wraperClassList.clear();
        getFieldsList();
        Beginning();
        return null;
     }
     
     public void setSelectAllCheckboxValue(List<fieldWraperClass> wraperClassList) {
        integer flag=1;
        isAllSelected=false;
        system.debug('wrapper List ====='+wraperClassList);
        for(fieldWraperClass obj: wraperClassList) {
            if(obj.isSelected!=true)  {
                flag=0;
                break;
            }
                
        }
        if(flag==1){
        isAllSelected=true;
        }
        else {
        isAllSelected=false;
        }
     }
     
     public class fieldWraperClass implements comparable{
        public String fieldName{get;set;}
        public String fieldLabel{get;set;}
        public Boolean isSelected{get;set;}
        public fieldWraperClass() {    
        }
        public fieldWraperClass(String fieldName, String fieldLabel, Boolean isSelected) {
            this.fieldName = fieldName;
            this.fieldLabel = fieldLabel;
            this.isSelected = isSelected;
        }
        public Integer compareTo(Object ObjToCompare) {
              fieldWraperClass that = (fieldWraperClass)ObjToCompare;       
              Integer returnValue = 0;      
              if ( this.fieldLabel > that.fieldLabel) { 
                  returnValue = 1;
              } else if ( this.fieldLabel < that.fieldLabel) {
                  returnValue = -1; 
              }
              return returnValue;
        
        }
     }
     
     public void SaveSetting(set<String> selectedFieldSet)
     {
        List<FieldHistoryTrackingSetting__c> toSaveList=new List<FieldHistoryTrackingSetting__c>();
        List<FieldHistoryTrackingSetting__c> listSavedFields=[select  Id,objectName__c,selectedFields__c, isSelected__c
                                                              from FieldHistoryTrackingSetting__c
                                                              WHERE objectName__c=:objects.subStringBefore(',') limit 1];  
        fieldvalue = '';               
        if(listSavedFields.size()>0) {
          if(selectedFieldSet.size()>0){
              for(String str : selectedFieldSet){
                 fieldvalue += ',' + str;
              }
          fieldvalue = fieldvalue.subString(1,fieldvalue.length());
         }
         else{
             fieldvalue = '';
         }
         if(String.isBlank(fieldvalue)) {
            listSavedFields[0].isSelected__c = false;
            listSavedFields[0].selectedFields__c = fieldvalue;             
         }
         else{
            listSavedFields[0].selectedFields__c = fieldvalue;
            listSavedFields[0].isSelected__c = true;
         }
        // update listSavedFields[0];
         Database.SaveResult[] srList = Database.update(listSavedFields, false);
         for(Database.SaveResult sr:srList) {
            if (sr.isSuccess())  {
                displayMessage();
                break;
            }
         }
       }    
       else {
          String commaSepratedList='';
          if(selectedFieldSet.size()>0) {
          for(String str : selectedFieldSet) {
             commaSepratedList += str + ',' ;
           }
           commaSepratedList = commaSepratedList.subString(0,commaSepratedList.length()-1);
           toSaveList.add(new FieldHistoryTrackingSetting__c(objectName__c = objects.subStringBefore(','),Object_Label__c=objects.substringAfter(',')+'('+objects.substringBefore(',')+')',selectedFields__c=commaSepratedList, isSelected__c=true));
           //insert toSaveList;  
           Database.SaveResult[] srList = Database.insert(toSaveList, false);
           for(Database.SaveResult sr:srList) { 
              if (sr.isSuccess())  {
                displayMessage();
                break;
              }
          }
          } 
       } 
     }
    public PageReference Cancel(){
    
    String baseUrl = System.URL.getSalesforceBaseUrl().toExternalForm();
    PageReference pageRef = new PageReference(baseUrl+'/home/home.jsp');
    pageRef.setRedirect(true);
    return pageRef ; 
    }
     // methods for pagination
    public void initializeFieldList () {   
        if (list_size == null) {
            list_size = 60;
        }     
        wraperClassList = new List<fieldWraperClass>();
        if (total_size < list_size) {
            system.debug('***total_size**'+total_size);
            for (Integer i = 0; i < total_size ; i++) {
                wraperClassList.add(wraperClassListNew[i]);
            }
        } else {
            for (Integer i = 0; i < list_size ; i++) {
                wraperClassList.add(wraperClassListNew[i]);
            }
        }
        if (counter > 0) {
            wraperClassList = new List<fieldWraperClass>();
            if (total_size - (counter+list_size) > 0 ) {
                for (Integer i = counter; i < counter+list_size; i++) {
                    wraperClassList.add(wraperClassListNew[i]);
                }
            } else {
                for (Integer i = counter; i < total_size; i++) {
                    wraperClassList.add(wraperClassListNew[i]);
                }
            }
        }
     }
     public PageReference Beginning() {
      counter = 0;
      initializeFieldList();
      if(wraperClassList.size()!=null) { 
            setSelectAllCheckboxValue(wraperClassList);   //method to set selectAllCheckBox value
        }
      return null;
    }
    public PageReference Previous() {
      isPrevious = true;
      counter -= list_size;
      initializeFieldList();
      if(wraperClassList.size()!=null) { 
            setSelectAllCheckboxValue(wraperClassList);   //method to set selectAllCheckBox value
        }
      return null;
    }

    public PageReference Next() {
      system.debug('%%Next%%%%');
      counter += list_size;
      system.debug('counter => '+counter);
      initializeFieldList();
      if(wraperClassList.size()!=null) { 
            setSelectAllCheckboxValue(wraperClassList);   //method to set selectAllCheckBox value
        }
     return null;
    }

    public PageReference End() {
        counter = total_size - math.mod(total_size, list_size);
        system.debug('Inside End'+counter);
        
        initializeFieldList();
        if(wraperClassList.size()!=null) { 
            setSelectAllCheckboxValue(wraperClassList);   //method to set selectAllCheckBox value
        }
        return null;
    }
    

    public Boolean getDisablePrevious() { 
          system.debug('Disable Previous');
        if (counter>0) return false; else return true;
      
    }

    public Boolean getDisableNext() {
           system.debug('Disable Next');
        if (counter + list_size < total_size) return false; else return true;
    }
}