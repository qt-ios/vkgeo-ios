import QtQuick 2.9
import QtQuick.Controls 2.2
import QtGraphicalEffects 1.0

import "../../Util.js" as UtilScript

Item {
    id: friendsSwipe

    function updateFriends(friends_list) {
        friendsListModel.clear();

        for (var i = 0; i < friends_list.length; i++) {
            friendsListModel.append(friends_list[i]);
        }
    }

    Image {
        id:                       refreshImage
        anchors.top:              parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width:                    UtilScript.pt(64)
        height:                   UtilScript.pt(64)
        source:                   "qrc:/resources/images/main/refresh.png"
        fillMode:                 Image.PreserveAspectFit
        visible:                  false

        PropertyAnimation {
            target:   refreshImage
            property: "rotation"
            from:     0
            to:       360
            duration: 500
            loops:    Animation.Infinite
            running:  refreshImage.visible
        }
    }

    ListView {
        id:           friendsListView
        anchors.fill: parent
        z:            1
        orientation:  ListView.Vertical

        model: ListModel {
            id: friendsListModel
        }

        delegate: Rectangle {
            width:        ListView.view.width
            height:       UtilScript.pt(80)
            clip:         true
            border.width: UtilScript.pt(1)
            border.color: "lightsteelblue"

            Row {
                anchors.fill: parent
                spacing:      UtilScript.pt(8)

                OpacityMask {
                    id:                     opacityMask
                    anchors.verticalCenter: parent.verticalCenter
                    width:                  UtilScript.pt(64)
                    height:                 UtilScript.pt(64)

                    source: Image {
                        width:    opacityMask.width
                        height:   opacityMask.height
                        source:   photoUrl
                        fillMode: Image.Stretch
                        visible:  false
                    }

                    maskSource: Image {
                        width:    opacityMask.width
                        height:   opacityMask.height
                        source:   "qrc:/resources/images/main/avatar_mask.png"
                        fillMode: Image.PreserveAspectFit
                        visible:  false
                    }
                }

                Text {
                    width:               parent.width - opacityMask.width
                    height:              parent.height
                    text:                "%1 %2".arg(firstName).arg(lastName)
                    color:               "black"
                    font.pointSize:      16
                    font.family:         "Helvetica"
                    horizontalAlignment: Text.AlignLeft
                    verticalAlignment:   Text.AlignVCenter
                    wrapMode:            Text.Wrap
                }
            }
        }

        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AlwaysOn
        }

        property bool refreshStarted: false

        onContentYChanged: {
            if (contentY < 0 - refreshImage.height) {
                if (!refreshStarted) {
                    refreshStarted = true;

                    refreshTimer.start();
                }
            } else {
                refreshImage.visible = false;

                refreshStarted = false;

                refreshTimer.stop();
            }
        }

        Timer {
            id:       refreshTimer
            interval: 500

            onTriggered: {
                refreshImage.visible = true;

                VKHelper.getFriends();
            }
        }
    }

    Component.onCompleted: {
        VKHelper.friendsReceived.connect(updateFriends);
    }
}