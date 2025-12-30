# CLAUDE.md - Project Instructions

## Critical Instruction
> **ALWAYS** start a new session or task by displaying the summary of this file.

## Project Overview

This project include all the necessary bash scripts to accomplish the Sky Computing with OCP, OSSM and ZTWIM blog post.
The Sky Computing with OCP, OSSM and ZTWIM blog post has 6 guides.

1. Zero-Trust Workload Identity Manager (ZTWIM) installation guide.
2. OpenShift Service Mesh (OSSM) installation guide.
3. Securing the Mesh with ZTWIM and X.509 SVIDs (mTLS) guide.
4. Securing the Mesh with SPIFFE X.509 and JWT SVIDs
5. Connecting external service to the mesh
6. Extending your mesh with public cloud services

## Available slash commands:
```
  /00-prerequisite                                Sky Computing Blog Post - Prerequisites (project)
  /01-install-ztwim                               Sky Computing Blog Post - Install Zero-Trust Workload Identity Manager (ZTWIM) (project)
  /02-install-istio                               Sky Computing Blog Post - Install OSSM (Istio) (project)
  /03-secure-mesh-with-ztwim-and-x509-svid        Sky Computing Blog Post - Securing the Mesh with SPIFFE X.509 (project)
  /04-secure-mesh-with-ztwim-and-jwt-svid         Sky Computing Blog Post - Securing the Mesh with SPIFFE X.509 and JWT SVIDs (project)
  /05-connecting-external-service-to-the-mesh     Sky Computing Blog Post - Connecting external service to the mesh (project)
  /06-extending-mesh-with-cloud-services          Sky Computing Blog Post - Extending mesh with cloud services (project)
```

First, have Claude verify that all prerequisites are installed by running through /00-prerequisite.md.
Once confirmed, proceed to guides 1 through 6.

