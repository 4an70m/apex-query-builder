# Apex-query-builder
Apex class which allows you to perform dynamic queries more elegant, then concatenating string into a SOQL request.

## Use-cases
There are situations, when you want to retrieve data from the Salesforce database, but you don't know what fields or what conditions you will need at the compilation time and you will now at the runtime. To handle this situations Salesforce provides a way to create dynamic SOQL from String, but generally this type of queries are quite complicated and String query building becomes an awkward process of building long, hardcoded query.

## References
 - [Select sObject](#Selecting-sObject)
 - [Add Fields](#Adding-fields)
 - [Add MORE fields](#Additional-methods)
 - [Limits, GROUP BYs, Offests](#CRUD-and-FLS-built-in-check)
 - [CRUD and FLS](#Results)
 - [Results](#dml-result)
 - [Conditions](#Conditions)
 - [Example](#Example-of-a-complex-query-builder)
 - [Test mock example](#Example-of-mocking-query-builder-in-test)

### Selecting sObject
```Apex
    new QueryBuilder(Account.class);
    new QueryBuilder('Account');
    new QueryBuilder(Account.getSobjectType());
    new QueryBuilder(new Account());
    
    new QueryBuilder().addFrom(Account.class);
    new QueryBuilder().addFrom('Account');
    new QueryBuilder().addFrom(Account.getSobjectType());
    new QueryBuilder().addFrom(new Account());
```

### Adding fields
```Apex
    new QueryBuilder(Account.class).addField(Account.Name);
    new QueryBuilder(Account.class).addField('Name');
    new QueryBuilder(Account.class).addField('Name, Id');
    new QueryBuilder(Account.class).addFields('Name, Id');
    new QueryBuilder(Account.class).addField(new List<String>{'Name'});
    new QueryBuilder(Account.class).addField(new Set<String>{'Name'});
```

### Adding MORE fields
#### All fields
```Apex
    new QueryBuilder(Account.class).addFieldsAll();
    new QueryBuilder(Account.class).addFieldsAllCreatable();
    new QueryBuilder(Account.class).addFieldsAllUpdatatble();
```
#### Field Sets
```Apex
    new QueryBuilder(Account.class).addFieldSet('Field_Set_Name');
    
    FieldSet retrievedFieldSet = ...//get fieldSet
    new QueryBuilder(Account.class).addFieldSet(retrievedFieldSet);
```
#### Sub queries 
```Apex
    new QueryBuilder(Account.class)
        .addSubQuery(new QueryBuilder('Contacts').addField(Contact.Name));
```

### Additional methods
```Apex
    new QueryBuilder(Account.class)
        .setLimit(1)
        .setOffset(1)
        .setOrderAsc('Id')
        .setOrderDesc(Account.Name)
        .setGroupBy('Id');
```

### CRUD and FLS built-in check
```Apex
    new QueryBuilder(Account.class).setCheckCRUDAndFLS(true);
    new QueryBuilder(Account.class).setCheckCRUD(false);
    new QueryBuilder(Account.class).setCheckFLS(); //true
```
### Results
```Apex
    //SELECT Id FROM Account
    new QueryBuilder(Account.class).toString();
    
    //SELECT count() FROM Account
    new QueryBuilder(Account.class).toStringCount();
    
    //1
    new QueryBuilder(Account.class).toCount();
    
    //[Account:(...)]
    new QueryBuilder(Account.class).toList();
    
    //[account_id=Account:(...)]
    new QueryBuilder(Account.class).toMap();
    
    //Account:(...)
    new QueryBuilder(Account.class).toSObject();
    
    //[account_id]
    new QueryBuilder(Account.class).toIdSet();
    
    //[account_id]
    new QueryBuilder(Account.class).extractIds('Id');
    
    //[account_name]
    new QueryBuilder(Account.class).extractField('Name');
```

### Conditions
#### Simple Condition
```Apex
    new QueryBuilder(Account.class)
        .addConditions()
        .add(new QueryBuilder.SimpleCondition('Name = \'Test\'')
        .endConditions();
```

#### Null Condition
```Apex
    new QueryBuilder(Account.class)
        .addConditionsWithOrder('1 AND 2')
        .add(new QueryBuilder.NullCondition('Name').isNull())
        .add(new QueryBuilder.NullCondition(Account.Id).notNull())
        .endConditions();
```

#### Compare Condition
```Apex
    new QueryBuilder(Account.class)
        .addConditionsWithOrder('1 OR 2 OR 3')
        .add(new QueryBuilder.CompareCondition('Name').eq('Test'))
        .add(new QueryBuilder.CompareCondition('Name').ne('Not Test'))
        .add(new QueryBuilder.CompareCondition('NumberOfEmployees').gt(0))
        .endConditions();
```

#### Like Condition
```Apex
    new QueryBuilder(Account.class)
        .addConditionsWithOrder('1')
        //Name LIKE '%st%'
        .add(new QueryBuilder.LikeCondition('Name').likeAnyBoth('st'))
        .endConditions();
```

#### In Condition
```Apex
    new QueryBuilder(Account.class)
        .addConditionsWithOrder('1 AND 2')
        .add(new QueryBuilder.InCondition('Name').inCollection(new List<String>{'Test'}))
        .add(new QueryBuilder.InCondition('Name').notIn(new Set<String>{'Not Test'}))
        .endConditions();
```

#### Record Type Condition
```Apex
    new QueryBuilder(Account.class)
        .addConditions()
        .add(new QueryBuilder.RecordTypeCondition('record_type_name'))
        .endConditions();
```

## Example of a complex query builder
```Apex
List<Account> accounts = (List<Account>) new QueryBuilder(Account.class)

        //fields
        .addField(Account.Name)
        .addField('ParentId')
        .addFields('Id, NumberOfEmployees')
        .addFields(new List<String>{'Name'})
        .addFields(new Set<String>{'Name'})
        .addFieldSet('name_of_the_field_set')
        .addFieldsAll()

        //subquery
        .addSubQuery(new QueryBuilder('Contacts')
            .addFieldsAll(Contact.class))

        //conditions
        .addConditions()
        .add(new QueryBuilder.SimpleCondition('Name = \'Account-1\''))
        .add(new QueryBuilder.NullCondition(Account.Name).notNull())
        .add(new QueryBuilder.CompareCondition(Account.Name).eq('Account-1'))
        .add(new QueryBuilder.LikeCondition(Account.Name).likeAnyRight('Account'))
        .add(new QueryBuilder.InCondition(Account.Name).inCollection(new Set<String>{'Account-1'}))
        .add(new QueryBuilder.RecordTypeCondition('name_of_the_record_type'))

        //order of execution of conditions
        .setConditionOrder('1 AND 2 OR ((3 AND 4) OR 5) AND 6')
        .endConditions()
        .setLimit(10)
        .setOffset(1)
        .addOrderAsc('Id')
        .preview()
        .toList();
```

## Example of mocking query builder in test
```Apex
@IsTest
public static void testStub1() {
        final String EXPECTED_SOQL = 'SELECT Name FROM Account';

        QueryBuilder stubbedQueryBuilder = new QueryBuilder(Account.class)
                .buildStub()
                .addStubToString(EXPECTED_SOQL)
                .addStubToList(new List<Account>{new Account(Name='Stubbed-Account')})
                .applyStub();

        System.assertEquals(EXPECTED_SOQL, stubbedQueryBuilder.toString());
        System.assertEquals(1, stubbedQueryBuilder.toList().size());
        System.assertEquals('Stubbed-Account', stubbedQueryBuilder.toList()[0].Name);
}
```
## ToDo
- Increase test coverage
- Refactor some functions/classes names
- Make IN conditions work with list references
- Improve Documentation
