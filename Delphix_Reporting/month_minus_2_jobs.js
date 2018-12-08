/*
 * Copyright (c) 2014, 2015 by Delphix. All rights reserved.
 */

'use strict';

load('lib/report-utils.js');

var RESULT_COL = 'result_month_minus_2_jobs';

var dependencies = [ 'Job' ];

var limit = dx.defineTunableInt({
    _id : 'prev2Month.limit',
    defaultValue : 200000,
    description : 'Maximum number of jobs to display',
    report : RESULT_COL
});

dx.updateMetadata(RESULT_COL, {
    name : '2nd Previous Month Jobs',
    type: dx.report.type.TABLE,
    category : dx.report.category.ACTIVITY,
    script : 'month_minus_2_jobs.js',
    tableHeaders : [ {
        mData : '_delphixEngineId',
        sTitle : 'Delphix Engine',
        renderFn : 'link'
    }, {
        mData : 'title',
        sTitle : 'Title'
    }, {
        mData : 'actionType',
        sTitle : 'Action'
    }, {
        mData : 'jobState',
        sTitle : 'Status'
    }, {
        mData : 'startTime',
        sTitle : 'Start time',
        sort : 'desc'
    }, {
        mData : 'updateTime',
        sTitle : 'Update time'
    }, {
        mData : 'duration',
        sTitle : 'Duration',
        renderFn : 'duration'
    }, {
        mData : 'targetName',
        sTitle : 'Target'
    }, {
        mData : 'user',
        sTitle : 'User'
    } ]
});

dx.checkDependencies(dependencies);

db.Job.ensureIndex({
    startTime : 1
});

var mm = new Date().getMonth()+1;        // base 0-11 ...
var yyyy = new Date().getFullYear();
//print (yyyy, mm);

var mm = mm - 2;       // 0=current month, 1 through 12 previous months ...
if (mm == 0) { var mm = 12; var yyyy = yyyy - 1 } 
//print (yyyy, mm);

var startDate = new Date(yyyy, mm-1, 1);   
//print (startDate);

var endDate = new Date(startDate.getFullYear(), startDate.getMonth()+1, 0);
//print (endDate);

var cond = {actionType : {$regex: '^DB_*'},"startTime": {'$gte': startDate, '$lte': endDate}};
//printjson (cond);

//db.Job.find(cond);
//db.Job.find(cond).pretty();

var result = db.Job.find( cond, {
        _delphixEngineId : 1,
        title : 1,
        actionType : 1,
        jobState : 1,
        startTime : 1,
        updateTime : 1,
        targetName : 1,
        user : 1
});

var jobs = result.toArray();

var userNameMap = dx.getNameMap('User');

jobs.forEach(function(doc) {
    doc.duration = doc.updateTime - doc.startTime;
    var userId = dx.getId(doc.user, doc._delphixEngineId);
    doc.user = userNameMap[userId];
});


dx.saveResults(RESULT_COL, jobs);
