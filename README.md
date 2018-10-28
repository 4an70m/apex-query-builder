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
        .field(Account.Name)
        .field('ParentId')
        .fields('Id, NumberOfEmployees')
        .fields(new List<String>{'Name'})
        .fields(new Set<String>{'Name'})
        .fieldSet('name_of_the_field_set')
        .fieldsAll()

        //subquery
        .subQuery(new QueryBuilder('Contacts').fieldsAll(Contact.class))

        //conditions
        .conditions()
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
        .orderAsc('Id')
        .preview()
        .toList();
```
