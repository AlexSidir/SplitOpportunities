@isTest(SeeAllData=true)
public with sharing class SubOpportunitiesTest {
    
    @isTest 
    public static void testCurrentOpportunityInfo() {
        Account acc = new Account(Name = 'Test Account');
        INSERT acc;

        Opportunity opp = new Opportunity(Name = 'Test Opp 1',
                                           AccountId = acc.Id,
                                           Amount = 10000,
                                           CloseDate = System.today(),
                                           StageName = 'Sales Qualified Lead (S1)',
                                           Already_Split__c = false, 
                                           Split_Opportunities__c = true,
                                           RelatedIDs__c = 100);

        INSERT opp;

        createSubOpportunities result = createSubOpportunities.currentOpportunityInfo(opp.Id); 
        
        System.assertEquals(opp.CloseDate, result.currentOpportunityCloseDate, 'Close Date does not match');
        System.assertEquals(opp.Amount, result.currentOpportunityAmount, 'Amount does not match');
        System.assertEquals(opp.Split_Opportunities__c, result.splitOpportunity, 'Split_Opportunities__c does not match');
        System.assertEquals(opp.RelatedIDs__c, result.relatedId, 'RelatedIDs__c does not match');
        System.assertEquals(opp.Already_Split__c, result.isAlreadySplit, 'Already_Split__c does not match');
    }

    @isTest 
    public static void testGetOpportunities() {
        Account acc = new Account(Name = 'Test Account');
        INSERT acc;

        Opportunity opp1 = new Opportunity(Name = 'Test Opp 1',
                                           AccountId = acc.Id,
                                           Amount = 10000,
                                           CloseDate = System.today(),
                                           StageName = 'Sales Qualified Lead (S1)',
                                           Already_Split__c = false, 
                                           Split_Opportunities__c = true,
                                           RelatedIDs__c = 256);

        INSERT opp1;

        Opportunity opp2 = new Opportunity(Name = 'Test Opp 2',
                                           AccountId = acc.Id,
                                           Amount = 10000,
                                           CloseDate = System.today(),
                                           StageName = 'Sales Qualified Lead (S1)',
                                           Already_Split__c = false, 
                                           Split_Opportunities__c = true,
                                           RelatedIDs__c = 256);

        INSERT opp2;

        Opportunity opp3 = new Opportunity(Name = 'Test Opp 3',
                                           AccountId = acc.Id,
                                           Amount = 10000,
                                           CloseDate = System.today(),
                                           StageName = 'Sales Qualified Lead (S1)',
                                           Already_Split__c = false, 
                                           Split_Opportunities__c = true,
                                           RelatedIDs__c = 200);

        INSERT opp3;

        List<Opportunity> result = createSubOpportunities.getOpportunities(256, opp1.Id);

        System.assertEquals(1, result.size(), 'RelatedIDs__c is not correct.');
        
        List<Opportunity> result2 = createSubOpportunities.getOpportunities(200, opp1.Id);

        System.assertEquals(1, result2.size(), 'RelatedIDs__c is not correct.');

        List<Opportunity> result3 = createSubOpportunities.getOpportunities(0, opp1.Id);

        System.assertEquals(0, result3.size(), 'RelatedIDs__c is not correct.');

    }

    @isTest
    public static void testCreateRecords() {
        
        //insert new RelatedOpportunitiesIDCount__c(Counter__c = 1); //This line needs to be used ONLY for deployment. Comment out when testing in the sandbox.
        
        Account account = new Account(Name = 'Test Account');
        INSERT account;
    	
        //-------------------------Test Opportunity--------------------------
        Opportunity opp = new Opportunity(Name = 'Test Opp 1',
                                           AccountId = account.Id,
                                           Amount = 10000,
                                           CloseDate = System.today(),
                                           StageName = 'Sales Qualified Lead (S1)',
                                           Already_Split__c = false, 
                                           Split_Opportunities__c = true,
                                           RelatedIDs__c = 100,
                                           Type = 'Existing Business',
                                           TotalOpportunityQuantity = 9000,
                                           Stage_1_VO__c = true,
                                           Stage_2_VO__c = true,
                                           Stage_3_VO__c = true,
                                           Stage_4_VO__c = false,
                                           Stage_5_VO__c = false,
                                           Description = 'Description of Opp',
                                           NextStep = 'Next Step Text',
                                           Lost_Reason__c = 'Other',
                                           LeadSource = 'Employee Referral',
                                           Last_Stage_Change__c = System.today() - 1);

        INSERT opp;

        createSubOpportunities.currentOpportunityInfo(opp.Id);

        List<Date> dates = new List<Date>();
        dates.add(System.today() + 1);
        dates.add(System.today() + 5);

        List<String> amounts = new List<String>();
        amounts.add('500');
        amounts.add('8490');

        Contact contact = new Contact(AccountId = account.Id, 
                                        LastName = 'Test Contact');
        INSERT contact;

        Id pricebookIdQuote = Test.getStandardPricebookId();

        Product2 prodQuote = new Product2(Name = 'Product Q',
                                     ProductCode = 'Pro-Q', 
                                     isActive = true);
        INSERT prodQuote;

        PricebookEntry pbEntryQuote = new PricebookEntry(Pricebook2Id = pricebookIdQuote,
                                                    Product2Id = prodQuote.Id,
                                                    UnitPrice = 100.00,
                                                    IsActive = true);
        INSERT pbEntryQuote;

        //------------------------Test Quote-------------------------------------
        Quote quote = new Quote(Name = 'Test Quote',
                                opportunityId = opp.id,
                                ShippingHandling = 55.0,
                                Status = 'In Review',
                                Description = 'Description of Quote',
                                ExpirationDate = System.today() + 30,
                                Tax = 32.0,
                                ContactId = contact.Id,
                                Email = 'test@test.com',
                                Phone = '1234666',
                                Fax = '6543211',
                                BillingStreet = 'Billing Street 5',
                                BillingPostalCode = 'Billing Code',
                                BillingName = 'Billing Name',
                                BillingCity = 'Billing City',
                                BillingState = 'Billing State',
                                BillingCountry = 'Billing Country',
                                ShippingStreet = 'Shipping Street 26',
                                ShippingCity = 'Shipping City',
                                ShippingCountry = 'Shipping Country',
                                ShippingState = 'Shipping State',
                                ShippingPostalCode = 'Shipping Postal Code',
                                ShippingName = 'Shipping Name',
                                Pricebook2Id = pricebookIdQuote);

        INSERT quote;

        //---------------------Test QuoteLineItems on Quote--------------------------
        QuoteLineItem currentQLT = new QuoteLineItem(QuoteId = quote.Id,
                                                                     UnitPrice = 10.0,
                                                                     Quantity = 23.0,
                                                                     Description = 'Test QuoteLineItems',
                                                                     Discount = 13,
                                                                     ServiceDate = System.today() + 22,
                                                                     PricebookEntryId = pbEntryQuote.Id);
        INSERT currentQLT;

        //---------------------Test ContentDocumentLink on Quote---------------------
        ContentVersion contentVersion = new ContentVersion(Title = 'Test',
                                                           PathOnClient = 'test.jpg',
                                                           VersionData = Blob.valueOf('Test Content'),
                                                           IsMajorVersion = true);
        INSERT contentVersion;

        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];

        ContentDocumentLink cdl = New ContentDocumentLink(LinkedEntityId = quote.Id,
                                                          ContentDocumentId = documents[0].Id,
                                                          ShareType = 'V');
        INSERT cdl;

        //---------------------Test ContentDocumentLink on Opportunity---------------
        ContentVersion contentVersionOpp = new ContentVersion(Title = 'TestOpp',
                                                           PathOnClient = 'testOpp.jpg',
                                                           VersionData = Blob.valueOf('Test Content Opportunity'),
                                                           IsMajorVersion = true);
        INSERT contentVersionOpp;

        List<ContentDocument> documentsOpp = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];

        ContentDocumentLink cdlOpp = New ContentDocumentLink(LinkedEntityId = opp.Id,
                                                          ContentDocumentId = documentsOpp[0].Id,
                                                          ShareType = 'V');
        INSERT cdlOpp;

        //----------------------Test OpportunityTeamMember--------------------------
        Profile profile = [SELECT Id FROM Profile WHERE Name='Tüv Standard User']; 
        User user = new User(Alias = 'testus', 
                          Email='standarduser@testorg.com', 
                          EmailEncodingKey='UTF-8',
                          LastName='Testing', 
                          LanguageLocaleKey='en_US',
                          LocaleSidKey='en_US', 
                          ProfileId = profile.Id, 
                          TimeZoneSidKey='America/Los_Angeles', 
                          UserName='standarduser@tüv.com');

        Insert user;

        OpportunityTeamMember otm = new OpportunityTeamMember (OpportunityId = opp.id, 
                                                               UserId = user.id,
                                                               TeamMemberRole = 'Sales Manager');
        INSERT otm;

        //-----------------------Test OpportunityContactRole------------------------
        OpportunityContactRole contactRole = new OpportunityContactRole(ContactId = contact.Id,
                                                                        OpportunityId = opp.Id,
                                                                        isPrimary = true);                  
        INSERT contactRole;

        //-----------------------Test OpportunityLineItems--------------------------
        Id pricebookId = Test.getStandardPricebookId();

        Product2 prod = new Product2(Name = 'Product X',
                                     ProductCode = 'Pro-X', 
                                     isActive = true);
        INSERT prod;

        PricebookEntry pbEntry = new PricebookEntry(Pricebook2Id = pricebookId,
                                                    Product2Id = prod.Id,
                                                    UnitPrice = 100.00,
                                                    IsActive = true);
        INSERT pbEntry;

        OpportunityLineItem oli = new OpportunityLineItem(OpportunityId = opp.Id,
                                                          Quantity = 5,
                                                          PricebookEntryId = pbEntry.Id);
        oli.TotalPrice = oli.Quantity * pbEntry.UnitPrice;
        
        INSERT oli;

        String result = createSubOpportunities.createRecords(opp.Id, dates, amounts);
        
        Opportunity oppResult1 = [SELECT Name, AccountId, CloseDate, StageName, Already_Split__c, RelatedIDs__c, Type, TotalOpportunityQuantity, 
                                        Stage_1_VO__c, Stage_2_VO__c, Stage_3_VO__c, Stage_4_VO__c, Stage_5_VO__c, Description, Amount, NextStep, 
                                        Lost_Reason__c, LeadSource, Last_Stage_Change__c FROM Opportunity WHERE Id =: result];
        
        System.assertEquals(opp.Name + ' 1', oppResult1.Name, 'Name does not match');
        System.assertEquals(Decimal.valueOf(amounts[0]), oppResult1.Amount, 'Amount does not match');
        System.assertEquals(opp.StageName, oppResult1.StageName, 'StageName does not match');
        System.assertEquals(opp.Type, oppResult1.Type, 'Type does not match');
        System.assertEquals(dates[0], oppResult1.CloseDate, 'CloseDate does not match');
        System.assertEquals(opp.Stage_1_VO__c, oppResult1.Stage_1_VO__c, 'Stage_1_VO__c does not match');
        System.assertEquals(opp.Stage_2_VO__c, oppResult1.Stage_2_VO__c, 'Stage_2_VO__c does not match');
        System.assertEquals(opp.Stage_3_VO__c, oppResult1.Stage_3_VO__c, 'Stage_3_VO__c does not match');
        System.assertEquals(opp.Stage_4_VO__c, oppResult1.Stage_4_VO__c, 'Stage_4_VO__c does not match');
        System.assertEquals(opp.Stage_5_VO__c, oppResult1.Stage_5_VO__c, 'Stage_5_VO__c does not match');
        System.assertEquals(opp.Description, oppResult1.Description, 'Description does not match');
        System.assertEquals(opp.NextStep, oppResult1.NextStep, 'NextStep does not match');
        System.assertEquals(opp.Lost_Reason__c, oppResult1.Lost_Reason__c, 'Lost_Reason__c does not match');
        System.assertEquals(opp.LeadSource, oppResult1.LeadSource, 'LeadSource does not match');
        System.assertEquals(opp.Last_Stage_Change__c, oppResult1.Last_Stage_Change__c, 'Last_Stage_Change__c does not match');
    
        List<Quote> quotesResult = [SELECT Id, Name, OpportunityId, ShippingHandling, Status, Description, ExpirationDate, Tax, ContactId, Email, Phone, Fax, 
                                     BillingStreet, BillingPostalCode, BillingName, BillingCity, BillingState, BillingCountry, ShippingStreet, ShippingCity, ShippingCountry, 
                                     ShippingState, ShippingPostalCode, ShippingName FROM Quote WHERE OpportunityId =: opp.Id];    

        for(Quote currentQuote: quotesResult){
            System.assertEquals(quote.Name, currentQuote.Name, 'Name does not match');
            System.assertEquals(quote.ShippingHandling, currentQuote.ShippingHandling, 'ShippingHandling does not match');
            System.assertEquals(quote.Status, currentQuote.Status, 'Status does not match');
            System.assertEquals(quote.Description, currentQuote.Description, 'Description does not match');
            System.assertEquals(quote.ExpirationDate, currentQuote.ExpirationDate, 'ExpirationDate does not match');
            System.assertEquals(quote.Tax, currentQuote.Tax, 'Tax does not match');
            System.assertEquals(quote.ContactId, currentQuote.ContactId, 'ContactId does not match');
            System.assertEquals(quote.Email, currentQuote.Email, 'Email does not match');
            System.assertEquals(quote.Phone, currentQuote.Phone, 'Phone does not match');
            System.assertEquals(quote.Fax, currentQuote.Fax, 'Fax does not match');
            System.assertEquals(quote.BillingStreet, currentQuote.BillingStreet, 'BillingStreet does not match');
            System.assertEquals(quote.BillingPostalCode, currentQuote.BillingPostalCode, 'BillingPostalCode does not match');
            System.assertEquals(quote.BillingName, currentQuote.BillingName, 'BillingName does not match');
            System.assertEquals(quote.BillingCity, currentQuote.BillingCity, 'BillingCity does not match');
            System.assertEquals(quote.BillingState, currentQuote.BillingState, 'BillingState does not match');
            System.assertEquals(quote.BillingCountry, currentQuote.BillingCountry, 'BillingCountry does not match');
            System.assertEquals(quote.ShippingStreet, currentQuote.ShippingStreet, 'ShippingStreet does not match');
            System.assertEquals(quote.ShippingCity, currentQuote.ShippingCity, 'ShippingCity does not match');
            System.assertEquals(quote.ShippingCountry, currentQuote.ShippingCountry, 'ShippingCountry does not match');
            System.assertEquals(quote.ShippingState, currentQuote.ShippingState, 'ShippingState does not match');
            System.assertEquals(quote.ShippingPostalCode, currentQuote.ShippingPostalCode, 'ShippingPostalCode does not match');
            System.assertEquals(quote.ShippingName, currentQuote.ShippingName, 'ShippingName does not match');
        }

        List<QuoteLineItem> quoteLineItems = [SELECT Id, QuoteId, UnitPrice, Quantity, Description, Discount, ServiceDate, Subtotal, PricebookEntryId
                                                  FROM QuoteLineItem WHERE QuoteId IN: quotesResult];

        for(QuoteLineItem testQLT: quoteLineItems) {
            System.assertEquals(currentQLT.UnitPrice, testQLT.UnitPrice, 'UnitPrice does not match');
            System.assertEquals(currentQLT.Quantity, testQLT.Quantity,'Quantity does not match');
            System.assertEquals(currentQLT.Description, testQLT.Description,'Description does not match');
            System.assertEquals(currentQLT.Discount, testQLT.Discount,'Discount does not match');
            System.assertEquals(currentQLT.ServiceDate, testQLT.ServiceDate,'ServiceDate does not match');
            System.assertEquals(currentQLT.Subtotal, testQLT.Subtotal,'Subtotal does not match');
        }

        List<ContentDocumentLink> files = [SELECT ContentDocumentId, ShareType, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId =: quote.Id];

        for(ContentDocumentLink currentFile: files) {
            System.assertEquals(cdl.ContentDocumentId, currentFile.ContentDocumentId, 'ContentDocumentId does not match');
            System.assertEquals(cdl.LinkedEntityId, currentFile.LinkedEntityId, 'LinkedEntityId does not match');
            System.assertEquals(cdl.ShareType, currentFile.ShareType, 'ShareType does not match');
        }

        List<OpportunityTeamMember> otms = [SELECT id, opportunityId, TeamMemberRole, UserId, OpportunityAccessLevel FROM OpportunityTeamMember WHERE opportunityId =: opp.Id];
        
        for(OpportunityTeamMember currentOtm : otms) {
            System.assertEquals(otm.UserId, currentOtm.UserId, 'UserId does not match');
            System.assertEquals(otm.TeamMemberRole, currentOtm.TeamMemberRole, 'TeamMemberRole does not match');
        }

        List<OpportunityLineItem> products = [SELECT Id, Quantity, UnitPrice, Description, ServiceDate, Discount FROM OpportunityLineItem WHERE OpportunityId =: opp.Id];

        for(OpportunityLineItem currentOLI: products) {
            System.assertEquals( oli.Quantity, currentOLI.Quantity, 'Quantity does not match');
            System.assertEquals( oli.UnitPrice, currentOLI.UnitPrice, 'UnitPrice does not match');
            System.assertEquals( oli.Description, currentOLI.Description, 'Description does not match');
            System.assertEquals( oli.ServiceDate, currentOLI.ServiceDate, 'ServiceDate does not match');
            System.assertEquals( oli.Discount, currentOLI.Discount, 'Discount does not match');
        }
    }
}