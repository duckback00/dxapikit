/*
 * Copyright (c) 2014, 2015 by Delphix. All rights reserved.
 */

'use strict';

load('lib/report-utils.js');

var RESULT_COL = 'result_recent_actions';

var dependencies = [ 'Action' ];

var limit = dx.defineTunableInt({
    _id : 'recent-actions.limit',
    defaultValue : 50000,
    description : 'Maximum number of recent actions to display',
    report : RESULT_COL
});

dx.updateMetadata(RESULT_COL, {
    name : 'Recent Actions',
    type: dx.report.type.TABLE,
    category : dx.report.category.ACTIVITY,
    script : 'recent-actions.js',
    tableHeaders : [ 
    { mData : '_delphixEngineId', sTitle : 'Delphix Engine', renderFn : 'link' }
  , { mData : 'tag', sTitle : 'Tag' }
  , { mData : 'title', sTitle : 'Title' }
  , { mData : 'actionType', sTitle : 'Action' }
  , { mData : 'details', sTitle : 'Details' }
  , { mData : 'state', sTitle : 'Status' }
  , { mData : 'startTime', sTitle : 'Start time', sort : 'desc' }
  , { mData : 'endTime', sTitle : 'End time' }
  , { mData : 'duration', sTitle : 'Duration', renderFn : 'duration' }
  , { mData : 'user', sTitle : 'User' } 
 ]
});

dx.checkDependencies(dependencies);


// Get alerts from the past 7 days by default

var cursor = db.Action.find().limit(limit);

var results = cursor.toArray();

var userNameMap = dx.getNameMap('User');

results.forEach(function(doc) {
    doc.duration = doc.endTime - doc.startTime;
    var userId = dx.getId(doc.user, doc._delphixEngineId);
    doc.user = userNameMap[userId];
});

dx.joinObjects(results, dx.getTags());
dx.saveResults(RESULT_COL, results);
