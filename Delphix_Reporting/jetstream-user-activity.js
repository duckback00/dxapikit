/*
 * Copyright (c) 2015 by Delphix. All rights reserved.
 */

'use strict';

/*
 * A report which displays a log of Jet Stream user actions over time. This is similar to the audit log report, but is
 * limited to Jet Stream user action types.
 */

load('lib/report-utils.js');
load('lib/underscore-min.js');

var RESULT_COL = 'result_jetstream_user_activity';

var dependencies = [ 'Action' ];

// Map jet stream user action types to human readable forms
var jetstreamUserActionTypes = {
    JETSTREAM_USER_BRANCH_CREATE: 'Create branch',
    JETSTREAM_USER_BRANCH_ACTIVATE: 'Activate branch',
    JETSTREAM_USER_BRANCH_DELETE: 'Delete branch',
    JETSTREAM_USER_CONTAINER_CREATE_BOOKMARK: 'Create bookmark',
    JETSTREAM_USER_BOOKMARK_SHARE: 'Share bookmark',
    JETSTREAM_USER_BOOKMARK_UNSHARE: 'Unshare bookmark',
    JETSTREAM_USER_BOOKMARK_DELETE: 'Delete bookmark',
    JETSTREAM_USER_CONTAINER_REFRESH: 'Refresh container',
    JETSTREAM_USER_CONTAINER_RESET: 'Reset container',
    JETSTREAM_USER_CONTAINER_DISABLE: 'Disable container',
    JETSTREAM_USER_CONTAINER_ENABLE: 'Enable container',
    JETSTREAM_USER_CONTAINER_RESTORE: 'Restore container'
};

var dateRange = dx.defineTunableInt({
    _id : 'jetstream.activity.dateRange',
    defaultValue : 180,
    description : 'Number of days worth of Jet Stream user actions to display',
    report : RESULT_COL
});

var limit = dx.defineTunableInt({
    _id : 'jetstream.activity.limit',
    defaultValue : 50000,
    description : 'Maximum number of Jet Stream user actions to display',
    report : RESULT_COL
});

dx.updateMetadata(RESULT_COL, {
    name : 'Jet Stream User Activity',
    type: dx.report.type.TABLE,
    category : dx.report.category.ACTIVITY,
    script : 'jetstream-user-activity.js',
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
        mData : 'details',
        sTitle : 'Detail'
    }, {
        mData : 'startTime',
        sTitle : 'Time',
        sort : 'desc'
    }, {
        mData : 'userName',
        sTitle : 'User'
    }, {
        mData : 'state',
        sTitle : 'State'
    } ]
});

dx.checkDependencies(dependencies);

db.Action.ensureIndex({
    title : 1,
    startTime: 1
});

// Get audit logs from the past 30 days by default
var fromDate = new Date();
fromDate.setDate(fromDate.getDate() - dateRange);

var cursor = db.Action.find({
    startTime : {
        $gt : fromDate
    },
    title : {
        $in : _.keys(jetstreamUserActionTypes)
    }
}, {
    _delphixEngineId : 1,
    startTime : 1,
    title : 1,
    details : 1,
    successful : 1,
    state : 1,
    user : 1,
    userName : 1
}).sort({
    startTime : -1
}).limit(limit);

/*
 * Build map from user ref to name
 * NOTE: auditEvent.userName was only added in 4.0. For older engines we need to look up the username.
 */
var userNameMap = dx.getNameMap('User');

var events = cursor.toArray();
events.forEach(function(doc) {
    if (!doc.userName && doc.user) {
        var userId = dx.getId(doc.user, doc._delphixEngineId);
        doc.userName = userNameMap[userId];
    }
    if (!doc.userName) {
        doc.userName = '';
    }
    delete doc.user;
    if (!doc.state) {
        // The "state" field was added in Eros and the "successful" field removed in 4.2
        doc.state = doc.successful ? 'COMPLETED' : 'FAILED';
        delete doc.successful;
    }

    // Replace action type with human readable version
    doc.title = jetstreamUserActionTypes[doc.title];
});

dx.joinObjects(events, dx.getTags());
dx.saveResults(RESULT_COL, events);
