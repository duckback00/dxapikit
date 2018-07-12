/*
 * Copyright (c) 2015 by Delphix. All rights reserved.
 */

'use strict';

load('lib/report-utils.js');

var RESULT_COL = 'result_recent_db_sync_jobs';

var dependencies = [ 'Job' ];

var limit = dx.defineTunableInt({
    _id : 'recent-db-sync-jobs.limit',
    defaultValue : 2000,
    description : 'Maximum number of DB_SYNC jobs to display',
    report : RESULT_COL
});

dx.updateMetadata(RESULT_COL, {
    name : 'Recent DB_SYNC Jobs',
    type: dx.report.type.TABLE,
    category : dx.report.category.ACTIVITY,
    script : 'recent-db-sync-jobs.js',
    dateRangeFilter : 'startTime',
    tableHeaders : [ {
        mData : '_delphixEngineId',
        sTitle : 'Delphix Engine',
        renderFn : 'link'
    }, {
        mData : 'tag',
        sTitle : 'Tag'
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
        mData : 'percentComplete',
        sTitle : 'Progress'
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
    }, ]
});

dx.checkDependencies(dependencies);

db.Job.ensureIndex({
    startTime : 1,
    actionType: 1
});

var result = db.Job.aggregate([ {
    $match : {
        actionType : 'DB_SYNC'
    }
}, {
    $sort : {
        startTime : -1
    }
}, {
    $limit : limit
}, {
    $project : {
        _delphixEngineId : 1,
        title : 1,
        actionType : 1,
        percentComplete: 1,
        jobState : 1,
        startTime : 1,
        updateTime : 1,
        targetName : 1,
        user : 1
    }
} ]);

var jobs = result.toArray();

var userNameMap = dx.getNameMap('User');

jobs.forEach(function(doc) {
    doc.duration = doc.updateTime - doc.startTime;
    var userId = dx.getId(doc.user, doc._delphixEngineId);
    doc.user = userNameMap[userId];
});

dx.joinObjects(jobs, dx.getTags());

dx.saveResults(RESULT_COL, jobs);
