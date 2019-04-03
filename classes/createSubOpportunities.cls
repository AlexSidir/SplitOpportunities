public with sharing class createSubOpportunities {
    
    @AuraEnabled public Decimal currentOpportunityAmount{ get; set; }
    @AuraEnabled public Date currentOpportunityCloseDate{ get; set; }
    @AuraEnabled public Boolean splitOpportunity{ get; set; }
    @AuraEnabled public Boolean isAlreadySplit{ get; set; }
    @AuraEnabled public Decimal relatedId { get; set; }
    
    @AuraEnabled
    public static createSubOpportunities currentOpportunityInfo(String recordId){
        
        createSubOpportunities obj = new createSubOpportunities();
        
        Opportunity opp = [SELECT Amount, Already_Split__c, Split_Opportunities__c, CloseDate, RelatedIDs__c
                           FROM Opportunity WHERE Id =: recordId LIMIT 1];
        
        obj.currentOpportunityAmount = opp.Amount;
        obj.isAlreadySplit = opp.Already_Split__c;
        obj.splitOpportunity = opp.Split_Opportunities__c;
        obj.currentOpportunityCloseDate = opp.CloseDate;
        obj.relatedId = opp.RelatedIDs__c;
        
        return obj;
    }
    
    @AuraEnabled
    public static List <Opportunity> getOpportunities(Decimal relatedId, String currentOppId) {
        return [SELECT Id, name,Amount, CloseDate FROM Opportunity WHERE RelatedIDs__c =: relatedId AND RelatedIDs__c != 0 AND RelatedIDs__c != null AND Id !=: currentOppId];
    }

    @AuraEnabled
    public static String createRecords(String recordId, List<Date> dates, List<String> amounts){
        
        RelatedOpportunitiesIDCount__c orgDefault = RelatedOpportunitiesIDCount__c.getOrgDefaults();
        orgDefault.Counter__c++;
        
        Opportunity opp = [SELECT Id, Name, RecordTypeId, AccountId, Description, Last_Stage_Change__c, StageName, LeadSource, NextStep, CurrencyIsoCode, 
                           Pricebook2Id, CampaignId, Probability, TotalOpportunityQuantity, Lost_Reason__c, Stage_1_VO__c,
                           Stage_2_VO__c, Stage_3_VO__c, Stage_4_VO__c, Stage_5_VO__c, Type, OwnerId, Private__c
                           FROM Opportunity WHERE Id =: recordId LIMIT 1];
        
        List<Opportunity> listToCreate = new List<Opportunity>();
        
        for(Integer i = 0; i < amounts.size(); i++)  {
            Opportunity subOpp = new Opportunity(Name = opp.Name + (' ' + (i + 1)),
                                                 AccountId = opp.AccountId,
                                                 Type = opp.Type,
                                                 OwnerId = opp.OwnerId,
                                                 Description = opp.Description,
                                                 
                                                 LeadSource = opp.LeadSource,
                                                 NextStep = opp.NextStep,
                                                 CurrencyIsoCode = opp.CurrencyIsoCode,
                                                 Pricebook2Id = opp.Pricebook2Id,
                                                 CampaignId = opp.CampaignId,
                                                 Private__c = opp.Private__c,
                                                 Probability = opp.Probability,
                                                 TotalOpportunityQuantity = opp.TotalOpportunityQuantity,
                                                 Lost_Reason__c = opp.Lost_Reason__c,
                                                 StageName = 'Sales Qualified Lead (S1)',
                                                 /*StageName = opp.StageName,
                                                 Stage_1_VO__c = opp.Stage_1_VO__c,
                                                 Stage_2_VO__c = opp.Stage_2_VO__c,
                                                 Stage_3_VO__c = opp.Stage_3_VO__c,
                                                 Stage_4_VO__c = opp.Stage_4_VO__c,
                                                 Stage_5_VO__c = opp.Stage_5_VO__c,*/
                                                 Split_Opportunities__c = false,
                                                 CloseDate = dates[i],
                                                 Amount = Decimal.valueOf(amounts[i]),
                                                 Already_Split__c = true,
                                                 RelatedIDs__c = orgDefault.Counter__c,
                                                 RecordTypeId = opp.RecordTypeId
                                                );
            
            listToCreate.add(subOpp);
        }
        
        UPSERT orgDefault;
        
        if(listToCreate.size() != 0) {
            
            Database.SaveResult[] srList = Database.Insert(listToCreate,false);
            
            List<OpportunityLineItem> oli = addProducts(opp, listToCreate);
            addQuotes(opp, listToCreate, oli);
            addOpportunityTeamMembers(opp, listToCreate);
            addContactRoles(opp, listToCreate);
            addFiles(opp, listToCreate);
            
            for(Integer i = 0; i < amounts.size(); i++)  {
                listToCreate[i].Last_Stage_Change__c = opp.Last_Stage_Change__c;
                listToCreate[i].StageName = opp.StageName;
                listToCreate[i].Stage_1_VO__c = opp.Stage_1_VO__c;
                listToCreate[i].Stage_2_VO__c = opp.Stage_2_VO__c;
                listToCreate[i].Stage_3_VO__c = opp.Stage_3_VO__c;
                listToCreate[i].Stage_4_VO__c = opp.Stage_4_VO__c;
                listToCreate[i].Stage_5_VO__c = opp.Stage_5_VO__c;
            }
            
            UPDATE listToCreate;//Update Opportunities after the Products have been added, due to Validation Rules
            
            for (Database.SaveResult sr : srList) {
                if (sr.isSuccess()) {
                    System.debug('Successfully inserted opportunity. Opportunity ID: ' + sr.getId());
                } else {
                    // Operation failed, so get all errors                
                    for(Database.Error err : sr.getErrors()) {
                        System.debug('The following error has occurred.');                    
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                        System.debug('Opportunity fields that affected this error: ' + err.getFields());
                    }
                    return 'Error Occured';
                }
            }
            Opportunity currentOpp = [SELECT Id FROM Opportunity WHERE Id=: recordId LIMIT 1];
            DELETE currentOpp;
            return listToCreate[0].Id; //Return first record Id to redirect the user to that record
        }
        return null;
    }
    
    public static void addQuotes(Opportunity opp, List<Opportunity> listToCreate, List<OpportunityLineItem> oli) {
        List<Quote> quotes = [SELECT Id, Name, OpportunityId, ShippingHandling, Status, Description, SAP_Quote_Number__c, ExpirationDate, Tax, ContactId, Email, Phone, Fax, 
                              BillingStreet, BillingPostalCode, BillingName, BillingCity, BillingState, BillingCountry, ShippingStreet, ShippingCity, ShippingCountry, 
                              ShippingState, ShippingPostalCode, ShippingName, Pricebook2Id FROM Quote WHERE OpportunityId =: opp.Id];
        
        List<Quote> quotesList = new List<Quote>();
        
        List<QuoteLineItem> qliList = new List<QuoteLineItem>();
        
        Set<Id> setF = new Set<Id>();
        
        if(quotes.size() != null && quotes.size() != 0) {
            for(Opportunity o : listToCreate) {
                for (Quote q : quotes){
                    Quote quote = new Quote(Name = q.name,
                                            opportunityId = o.id,
                                            ShippingHandling = q.ShippingHandling,
                                            Status = q.Status,
                                            Description = q.Description, 
                                            //SAP_Quote_Number__c = q.SAP_Quote_Number__c,
                                            ExpirationDate = q.ExpirationDate,
                                            Tax = q.Tax,
                                            BillingStreet = q.BillingStreet,
                                            ContactId = q.ContactId,
                                            Email = q.Email,
                                            Phone = q.Phone,
                                            Fax = q.Fax,
                                            BillingPostalCode = q.BillingPostalCode,
                                            BillingName = q.BillingName,
                                            BillingCity = q.BillingCity,
                                            BillingState = q.BillingState,
                                            BillingCountry = q.BillingCountry,
                                            ShippingStreet = q.ShippingStreet,
                                            ShippingCity = q.ShippingCity,
                                            ShippingCountry = q.ShippingCountry,
                                            ShippingState = q.ShippingState,
                                            ShippingPostalCode = q.ShippingPostalCode,
                                            ShippingName = q.ShippingName,
                                            Pricebook2Id = q.Pricebook2Id);
                    
                    quotesList.add(quote);
                    setF.add(q.Id);
                }
            }
            UPSERT quotesList;
            
            List<ContentDocumentLink> files = [SELECT ContentDocumentId, ShareType, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId IN: setF];
            List<ContentDocumentLink> filesList = new List<ContentDocumentLink>();
            
            if(files.size() != null && files.size() != 0) {
                for(Quote q: quotesList) {
                    for (ContentDocumentLink currentFile: files){
                        ContentDocumentLink file = new ContentDocumentLink(ContentDocumentId = currentFile.ContentDocumentId,
                                                                           ShareType = currentFile.ShareType,
                                                                           LinkedEntityId = q.Id);
                        filesList.add(file);
                    }
                }
                UPSERT filesList;
                
                DELETE files;
            }
            
            /*List<QuoteLineItem> oppLineItemsForQuote = new List<QuoteLineItem>();

            if(oli.size() != null && oli.size() != 0) {
                for(Quote q: quotesList) {
                    for (OpportunityLineItem oliList : oli){
                        QuoteLineItem currentOLI = new QuoteLineItem(QuoteId = q.Id,
                                                                     UnitPrice = oliList.UnitPrice,
                                                                     Quantity = oliList.Quantity,
                                                                     Description = oliList.Description,
                                                                     Discount = oliList.Discount,
                                                                     ServiceDate = oliList.ServiceDate,
                                                                     Product2Id = oliList.Product2Id,
                                                                     PricebookEntryId = oliList.PricebookEntryId);
                        
                        oppLineItemsForQuote.add(currentOLI);
                    }
                }
                 UPSERT oppLineItemsForQuote;
            }*/

            List<QuoteLineItem> quoteLineItems = [SELECT Id, QuoteId, UnitPrice, Quantity, Description, Discount, ServiceDate, Product2Id, Subtotal, PricebookEntryId
                                                  FROM QuoteLineItem WHERE QuoteId IN: setF];
            
            if(quoteLineItems.size() != null && quoteLineItems.size() != 0) {
                for(Quote q: quotesList) {
                    
                    for (QuoteLineItem qli : quoteLineItems){
                        QuoteLineItem currentQLT = new QuoteLineItem(QuoteId = q.Id,
                                                                     UnitPrice = qli.UnitPrice,
                                                                     Quantity = qli.Quantity,
                                                                     Description = qli.Description,
                                                                     Discount = qli.Discount,
                                                                     ServiceDate = qli.ServiceDate,
                                                                     Product2Id = qli.Product2Id,
                                                                     PricebookEntryId = qli.PricebookEntryId);
                        
                        qliList.add(currentQLT);
                    }
                }
                UPSERT qliList;
            }
            DELETE quotes; //Delete quotes since we are creating new ones
        }
    }
    
    public static void addOpportunityTeamMembers(Opportunity opp, List<Opportunity> listToCreate) {
        List<OpportunityTeamMember> otms = [SELECT id, opportunityId, TeamMemberRole, UserId, OpportunityAccessLevel FROM OpportunityTeamMember WHERE opportunityId =: opp.Id];//Querying existing Team Members on the opportunity
        
        List<OpportunityTeamMember> teamMemberList = new List<OpportunityTeamMember>();
        
        if(otms.size() != null && otms.size() != 0) {
            for(Opportunity o : listToCreate) {
                for (OpportunityTeamMember currentMember : otms){
                    OpportunityTeamMember member = new OpportunityTeamMember(OpportunityId = o.Id,
                                                                             UserId = currentMember.UserId,
                                                                             TeamMemberRole = currentMember.TeamMemberRole,
                                                                             OpportunityAccessLevel = currentMember.OpportunityAccessLevel);
                    teamMemberList.add(member); 
                }
            }
            UPSERT teamMemberList;
            
            DELETE otms;
        }
    }
    
    public static void addContactRoles(Opportunity opp, List<Opportunity> listToCreate) {
        List<OpportunityContactRole> ocr = [SELECT Id, ContactId, isPrimary, Role FROM OpportunityContactRole WHERE OpportunityId = : opp.Id];//Querying existing Contact Roles on the opportunity
        
        List<OpportunityContactRole> contactRoleList = new List<OpportunityContactRole>();
        
        if(ocr.size() != null && ocr.size() != 0) {
            for(Opportunity o : listToCreate) {
                for (OpportunityContactRole currentContactRole: ocr){
                    OpportunityContactRole contactRole = new OpportunityContactRole(ContactId = currentContactRole.ContactId,
                                                                                    OpportunityId = o.Id,
                                                                                    isPrimary = currentContactRole.isPrimary,
                                                                                    Role = currentContactRole.Role);
                    contactRoleList.add(contactRole); 
                }
            }
            UPSERT contactRoleList;
            
            DELETE ocr;
        }
    }
    
    public static void addFiles(Opportunity opp, List<Opportunity> listToCreate) {
        List<ContentDocumentLink> files = [SELECT ContentDocumentId, ShareType, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId =: opp.Id]; //Querying existing files on the opportunity
        
        List<ContentDocumentLink> filesList = new List<ContentDocumentLink>();
        
        if(files.size() != null && files.size() != 0) {
            for(Opportunity o : listToCreate) {
                for (ContentDocumentLink currentFile: files){
                    ContentDocumentLink file = new ContentDocumentLink(ContentDocumentId = currentFile.ContentDocumentId,
                                                                       ShareType = currentFile.ShareType,
                                                                       LinkedEntityId = o.Id);
                    filesList.add(file);
                }
            }
            UPSERT filesList;
            
            DELETE files;
        }
    }
    
    public static List<OpportunityLineItem> addProducts(Opportunity opp, List<Opportunity> listToCreate) {
        List<OpportunityLineItem> oli = [ SELECT Id, OpportunityID, Product2Id, ProductCode, ListPrice, Quantity, UnitPrice, Description,
                                         ServiceDate, Discount, PricebookEntryId FROM OpportunityLineItem WHERE OpportunityId =: opp.Id];
        
        List<OpportunityLineItem> productList = new List<OpportunityLineItem>();
        
        if(oli.size() != null && oli.size() != 0) {
            for(Opportunity o : listToCreate) {
                for (OpportunityLineItem currentProduct: oli){
                    OpportunityLineItem product = new OpportunityLineItem(OpportunityID = o.Id,
                                                                          PricebookEntryId = currentProduct.PricebookEntryId,
                                                                          Product2Id = currentProduct.Product2Id,
                                                                          Quantity = currentProduct.Quantity,
                                                                          UnitPrice = currentProduct.UnitPrice,
                                                                          Description = currentProduct.Description,
                                                                          ServiceDate = currentProduct.ServiceDate,
                                                                          Discount = currentProduct.Discount);

                    productList.add(product);
                }
            }
            UPSERT productList;
            return productList;
            //DELETE oli; //Its not needed since the opportunity is deleted
        }
        return null;
    }
}
