# Resources set and racks


## Rack
Each rack is a fault domain.
You define racks with a `type` value: `zone` or `node` (per node).
Rack is mapped with a label on the pod `rack`.
`rack` can be any string. 


## Resource set
A resource set is an abstraction over racks. 
A resource set can have a rack assigned.
Rack is mapped with a label on the pod `resource-set`.
`resource-set` can be any string. 


## Deployments
For each deployment you select a `resource-set`.
If the assigned `resource-set` has a `rack`, then all the pods of that deployment will be in the same fault domain.
If the assigned `resource-set` doesn't have a `rack`, then all the pods of that deployment will spread over different fault domains.

## Examples (see the .yaml in this directory)
We have two kind of deployments: `broker` and `proxy`.
We define 4 brokers set:
1. shared1, assigned to zone1
2. shared2, assigned to zone2
3. customer1, no zone rack assigned
4. customer2, no zone rack assigned

We define 2 proxyes set:
1. shared1, assigned to zone1
2. shared2, assigned to zone2


Combininig podAffinity and podAntiAffinity rules we obtain this scenario:
1. broker-shared1 pods are all deployed in the failure domain zone1
2. broker-shared2 pods are all deployed in the failure domain zone2
3. broker-customer-1 pods are deployed across all the failure domains
4. broker-customer-2 pods are deployed across all the failure domains
5. proxy-shared1 pods are all deployed in the failure domain zone1
6. proxy-shared2 pods are all deployed in the failure domain zone2


The advantage of this solution is that each deployment can be scaled-up and scaled-down independently.




