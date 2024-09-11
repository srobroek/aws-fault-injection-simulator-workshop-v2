#!/usr/bin/env node
import 'source-map-support/register';
import { Services } from '../lib/services';
import { Applications } from '../lib/applications';
//import { EKSPetsite } from '../lib/ekspetsite'
import { App, Tags, Aspects, Tag, IAspect } from 'aws-cdk-lib';
import { IConstruct } from 'constructs';
import { AwsSolutionsChecks } from 'cdk-nag';
import { FisServerless } from '../lib/fis_serverless';
import { Observability } from '../lib/observability'
import { LoadTesting } from '../lib/load_testing';

import {v4 as uuid} from 'uuid'
const stackName = "Services";
const app = new App();

const stack = new Services(app, stackName, { 
  env: { 
    account: process.env.CDK_DEFAULT_ACCOUNT, 
    region: process.env.CDK_DEFAULT_REGION 
}});

const applications = new Applications(app, "Applications", {
  env: { 
    account: process.env.CDK_DEFAULT_ACCOUNT, 
    region: process.env.CDK_DEFAULT_REGION 
}});

const fis_serverless = new FisServerless(app, "FisServerless", {
  env: { 
    account: process.env.CDK_DEFAULT_ACCOUNT, 
    region: process.env.CDK_DEFAULT_REGION 
}});

const observability = new Observability(app, "Observability", {
  env: {
      account: process.env.CDK_DEFAULT_ACCOUNT, 
      region: process.env.CDK_DEFAULT_REGION 
}});

const load_testing = new LoadTesting(app, "LoadTesting", {
  env: { 
    account: process.env.CDK_DEFAULT_ACCOUNT, 
    region: process.env.CDK_DEFAULT_REGION 
}});

//Walk across all resources to tag them with a random uuid flag.
// We will overwrite this later in the specific resource

class UuidTagger implements IAspect {
    visit(node: IConstruct) {
        new Tag("flag", uuid() ).visit(node)}
    }

Aspects.of(app).add(new UuidTagger())
Tags.of(app).add("Workshop","true")
Tags.of(app).add("AzImpairmentPower","Ready")
//Aspects.of(stack).add(new AwsSolutionsChecks({verbose: true}));
//Aspects.of(applications).add(new AwsSolutionsChecks({verbose: true}));
