# Apex-query-builder
Apex class which allows you to perform dynamic queries more elegant, then concatenating string into a SOQL request.

## Use-cases
There are situations, when you want to retrieve data from the Salesforce database, but you don't know what fields or what conditions you will need at the compilation time and you will now at the runtime. To handle this situations Salesforce provides a way to create dynamic SOQL from String, but generally this type of queries are quite complicated and String query building becomes an awkward process of building long, hardcoded query.

## Usage
The final version of the QueryBuilder is still pending, as this is still under development, but the current version is already usable.

Most of the example can be found in the unit test.

Example of a complex query builder
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
        .addSubQuery(new QueryBuilder('Contacts').fieldsAll(Contact.class))

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

Example of mock query builder in test
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

