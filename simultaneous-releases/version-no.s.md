# Version No.s

When doing a simultaneous release Pub Release sets the same no. for every package.

Management of version no.s is a little difficult because of the pub.dev policy that once a package is published you cannot unpublish the package.

The consequences of this is that, if a simultaneous release fails after it publishes at least one package, then the version no. must again be incremented.

As the outermost package is the first to be published we use the version no. from the outermost package to determine the new version no.

To avoid too many failed releases we recommend that you us the --dry-run switch to ensure that everything is in order before you do the actual publish.

