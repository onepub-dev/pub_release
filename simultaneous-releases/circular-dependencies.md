# Circular dependencies

If you have projects with circular dependencies then you are in for some pain.

A circular dependencies is where A depends on B and B depends on A. 

With a circular dependency as above, package 'A' must be published before package 'B' but package 'B' must be published before package 'A'. You can get around this problem by creating a temporary package \(A or B\) that isn't dependent on the other.

The correct approach is to move the common code from each package into a third package 'C' that both 'A' and 'B' depend on.

