# Commands

Before you attempt a release you should do a dry run

```text
pub_release multi --dry-run
or
pub_release mulit -d
```

Pub Release will run a dry run on your release to allow you to do basic checks across all of your projects.

The dry will will perform each of the following actions:

* check that all code is committed
* run analyze over your code
* format your code
* run unit tests for each package

You can skip the unit tests by passing:

```text
pub_release multi -d -no-test
```

Once you are ready to perform a release run:

```text
pub_release multi
```

The `multi` command will still run analyze and format but it will not run the unit tests but it will warn you if a successful unit test run has not been completed for each package.





