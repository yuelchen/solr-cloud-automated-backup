# solr-cloud-automated-backup
An automated backup script to take a "snapshot" of a Solr-cloud collection on Linux instance. 

# What is Solr?
Apache Solr is an open source software written in Java and developed as part of Apache Lucene project. 
The purpose of this software is to power the search and navigational features of large applications.
One of it's major features which makes this possible is the indexing of data to allow quicker retrieval.

# Solr Cloud versus Solr (Stand-alone)
Solr cloud is a distributed architecture with multiple nodes and typically a multi-node zookeeper cluster. 
A stand-alone solr implementation is a single node with solr running on it and is a single point failure. 
This repository is to backup solr cloud and not solr stand-alone implementation - to do so, simply execute the back-up command on the single node. 
The back-up command can be found on apache solr documentation for your Solr version. 
