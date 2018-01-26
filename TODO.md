1. Create VPC
1. Add web node
1. Verify web server can be reached
1. Add user/role with admin access to the VPC and it's resources (and only the VPC)
1. Figure out credentials?
1. What about ssh keys?


1. Build packer script for saleor
1. Use saleor in place of nginx above (spin up from <latest> AMI)

1. Build packer script for locust
1. Add locust to the VPC.

1. Set up security groups for locust and web access
1. Verify we can build VPC and user from scratch that could do the workshop

1. Create a new VPC with resource on each run
1. Can you interrogate a user for a public ssh key?
1. Maybe allow them to paste in an SSH key as-well?


## End goal
Web / console UI that can spin up a VPC for a workshop and give a student an IAM login with change on first-use type password.

User can:
* Use admin console to see VPC resources
* start/stop machines
* ssh into machines

User cannot:
* See/control things outside their VPC
* Launch new instances / increase sizes, anything like that.
