<%--
    Mango - Open Source M2M - http://mango.serotoninsoftware.com
    Copyright (C) 2006-2011 Serotonin Software Technologies Inc.
    @author Matthew Lohbihler
    
    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/.
--%>
<%@ include file="/WEB-INF/jsp/include/tech.jsp" %>
<%@page import="com.serotonin.mango.Common"%>
<%@page import="com.serotonin.mango.view.ShareUser"%>
<tag:page dwr="WatchListDwr" js="view" onload="init">
  <jsp:attribute name="styles">
    <style>
    html > body .dojoTreeNodeLabelSelected {
        background-color: inherit;
        color: inherit;
    }
    .watchListAttr {
        min-width:600px;
    }
    .rowIcons img {
        padding-right: 3px;
    }
    html > body .dojoSplitContainerSizerH {
        border: 1px solid #FFFFFF;
        background-color: #F07800;
        margin-top:4px;
        margin-bottom:4px;
    }
    .wlComponentMin {
        top:0px;
        left:0px;
        position:relative;
        margin:0px;
        padding:0px;
        width:16px;
        height:16px;
    }
    </style>
  </jsp:attribute>
  
  <jsp:body>
    <script type="text/javascript">
      dojo.require("dojo.widget.SplitContainer");
      dojo.require("dojo.widget.ContentPane");
      mango.view.initWatchlist();
      mango.share.dwr = WatchListDwr;
      var owner;
      var pointNames = {};
      var watchlistChangeId = 0;
      
      function init() {
          WatchListDwr.init(function(data) {
              mango.share.users = data.shareUsers;
              
              // Create the point tree.
              var rootFolder = data.pointFolder;
              var tree = dojo.widget.manager.getWidgetById('tree');
              var i;
              
              for (i=0; i<rootFolder.subfolders.length; i++)
                  addFolder(rootFolder.subfolders[i], tree);
              
              for (i=0; i<rootFolder.points.length; i++)
                  addPoint(rootFolder.points[i], tree);
              
              hide("loadingImg");
              //show("treeDiv");
              
              addPointNames(rootFolder);
              
              // Add default points.
              displayWatchList(data.selectedWatchList);
              maybeDisplayDeleteImg();
          });
          WatchListDwr.getDateRangeDefaults(<c:out value="<%= Common.TimePeriods.DAYS %>"/>, 1, function(data) { setDateRange(data); });
          var handler = new TreeClickHandler();
          dojo.event.topic.subscribe("tree/titleClick", handler, 'titleClick');
          dojo.event.topic.subscribe("tree/expand", handler, 'expand');
      }
      
      function addPointNames(folder) {
          var i;
          for (i=0; i<folder.points.length; i++)
              pointNames[folder.points[i].key] = folder.points[i].value;
          for (i=0; i<folder.subfolders.length; i++)
              addPointNames(folder.subfolders[i]);
      }
      
      function addFolder(folder, parent) {
          var folderNode = dojo.widget.createWidget("TreeNode", {
                  title: "<img src='images/folder_brick.png'/> "+ folder.name,
                  isFolder: "true",
                  lazyLoadData: folder
          });
          parent.addChild(folderNode);
      }
      
      function populateFolder(folderNode, lazyLoadData) {
          // Turn this off so as not to confuse the tree node.
          folderNode.isExpanded = false;
          
          var i;
          for (i=0; i<lazyLoadData.subfolders.length; i++)
              addFolder(lazyLoadData.subfolders[i], folderNode);
          
          for (i=0; i<lazyLoadData.points.length; i++) {
              addPoint(lazyLoadData.points[i], folderNode);
              if ($("p"+ lazyLoadData.points[i].key))
                  togglePointTreeIcon(lazyLoadData.points[i].key, false);
          }
          
          folderNode.expand();
      }
      
      function addPoint(point, parent) {
          var pointNode = dojo.widget.createWidget("TreeNode", {
                  title: "<img src='images/icon_comp.png'/> <span id='ph"+ point.key +"Name'>"+ point.value +"</span> "+
                          "<img src='images/bullet_go.png' id='ph"+ point.key +"Image' title='<fmt:message key="watchlist.addToWatchlist"/>'/>",
                  object: point
          });
          parent.addChild(pointNode);
          $("ph"+ point.key +"Image").mangoName = "pointTreeIcon";
      }
      
      var TreeClickHandler = function() {
          this.titleClick = function(message) {
              var widget = message.source;
              if (!widget.isFolder)
                  addToWatchList(widget.object.key);
          },
          
          this.expand = function(message) {
              if (message.source.lazyLoadData) {
                  var lazyLoadData = message.source.lazyLoadData;
                  delete message.source.lazyLoadData;
                  populateFolder(message.source, lazyLoadData);
              }
          }
      }
      
      function displayWatchList(data) {
          if (!data.points)
              // Couldn't find the watchlist. Reload the page
              window.location.reload();
          
          var points = data.points;
          owner = data.access == <c:out value="<%= ShareUser.ACCESS_OWNER %>"/>;
          
          // Add the new rows.
          for (var i=0; i<points.length; i++) {
              if (!pointNames[points[i]]) {
                  // The point id isn't in the list. Refresh the page to ensure we have current data.
                  window.location.reload();
                  return;
              }
              addToWatchListImpl(points[i]);
          }
          
          fixRowFormatting();
          mango.view.watchList.reset();
          
          var select = $("watchListSelect");
          var txt = $("newWatchListName");
          $set(txt, select.options[select.selectedIndex].text);
          
          // Display controls based on access
          var iconSrc;
          if (owner) {
              show("wlEditDiv", "inline");
              show("usersEditDiv", "inline");
              
              // Set the share users.
              mango.share.writeSharedUsers(data.users);
              iconSrc = "images/bullet_go.png";
          }
          else {
              hide("wlEditDiv");
              hide("usersEditDiv");
              iconSrc = "images/bullet_key.png";
          }
          
          var icons = getElementsByMangoName($("treeDiv"), "pointTreeIcon");
          for (var i=0; i<icons.length; i++)
              icons[i].src = iconSrc;
      }
      
      function showWatchListEdit() {
          openLayer("wlEdit");
          $("newWatchListName").select();
      }
    
      function saveWatchListName() {
          var name = $get("newWatchListName");
          var select = $("watchListSelect");
          select.options[select.selectedIndex].text = name;
          WatchListDwr.updateWatchListName(name);
          hideLayer("wlEdit");
      }
      
      function watchListChanged() {
          // Clear the list.
          var rows = getElementsByMangoName($("watchListTable"), "watchListRow");
          for (var i=0; i<rows.length; i++)
              removeFromWatchListImpl(rows[i].id.substring(1));
          
          watchlistChangeId++;
          var id = watchlistChangeId;
          WatchListDwr.setSelectedWatchList($get("watchListSelect"), function(data) {
        	  if (id == watchlistChangeId)
                  displayWatchList(data);
          });
      }
      
      function addWatchList(copy) {
    	  var copyId = ${NEW_ID};
    	  if (copy)
              copyId = $get("watchListSelect");
    	  
          WatchListDwr.addNewWatchList(copyId, function(watchListData) {
              var wlselect = $("watchListSelect");
              wlselect.options[wlselect.options.length] = new Option(watchListData.value, watchListData.key);
              $set(wlselect, watchListData.key);
              watchListChanged();
              maybeDisplayDeleteImg();
          });
      }
      
      function deleteWatchList() {
          var wlselect = $("watchListSelect");
          var deleteId = $get(wlselect);
          wlselect.options[wlselect.selectedIndex] = null;
          
          watchListChanged();
          WatchListDwr.deleteWatchList(deleteId);
          maybeDisplayDeleteImg();
      }
      
      function maybeDisplayDeleteImg() {
          var wlselect = $("watchListSelect");
          display("watchListDeleteImg", wlselect.options.length > 1);
      }
      
      function showWatchListUsers() {
          openLayer("usersEdit");
      }
      
      function openLayer(nodeId) {
          var nodeDiv = $(nodeId);
          closeLayers(nodeId);
          var divBounds = getNodeBounds(nodeDiv);
          var ancBounds = getNodeBounds(findRelativeAncestor(nodeDiv));
          nodeDiv.style.left = (ancBounds.w - divBounds.w - 30) +"px";
          showLayer(nodeDiv, true);
      }
    
      function closeLayers(exclude) {
          if (exclude != "wlEdit")
              hideLayer("wlEdit");
          if (exclude != "usersEdit")
              hideLayer("usersEdit");
      }
      
      
      //
      // Watch list membership
      //
      function addToWatchList(pointId) {
          // Check if this point is already in the watch list.
          if ($("p"+ pointId) || !owner)
              return;
          addToWatchListImpl(pointId);
          WatchListDwr.addToWatchList(pointId, mango.view.watchList.setDataImpl);
          fixRowFormatting();
      }
      
      var watchListCount = 0;
      function addToWatchListImpl(pointId) {
          watchListCount++;
      
          // Add a row for the point by cloning the template row.
          var pointContent = createFromTemplate("p_TEMPLATE_", pointId, "watchListTable");
          pointContent.mangoName = "watchListRow";
          
          if (owner) {
              show("p"+ pointId +"MoveUp");
              show("p"+ pointId +"MoveDown");
              show("p"+ pointId +"Delete");
          }
          
          $("p"+ pointId +"Name").innerHTML = pointNames[pointId];
          
          // Disable the element in the point list.
          togglePointTreeIcon(pointId, false);
      }
      
      function removeFromWatchList(pointId) {
          removeFromWatchListImpl(pointId);
          fixRowFormatting();
          WatchListDwr.removeFromWatchList(pointId);
      }
      
      function removeFromWatchListImpl(pointId) {
          watchListCount--;
          var pointContent = $("p"+ pointId);
          var watchListTable = $("watchListTable");
          watchListTable.removeChild(pointContent);
          
          // Enable the element in the point list.
          togglePointTreeIcon(pointId, true);
      }
      
      function togglePointTreeIcon(pointId, enable) {
          var node = $("ph"+ pointId +"Image");
          if (node) {
              if (enable)
                  dojo.html.setOpacity(node, 1);
              else
                  dojo.html.setOpacity(node, 0.2);
          }
      }
      
      //
      // List state updating
      //
      function moveRowDown(pointId) {
          var watchListTable = $("watchListTable");
          var rows = getElementsByMangoName(watchListTable, "watchListRow");
          var i=0;
          for (; i<rows.length; i++) {
              if (rows[i].id == pointId)
                  break;
          }
          if (i < rows.length - 1) {
              if (i == rows.length - 1)
                  watchListTable.append(rows[i]);
              else
                  watchListTable.insertBefore(rows[i], rows[i+2]);
              WatchListDwr.moveDown(pointId.substring(1));
              fixRowFormatting();
          }
      }
      
      function moveRowUp(pointId) {
          var watchListTable = $("watchListTable");
          var rows = getElementsByMangoName(watchListTable, "watchListRow");
          var i=0;
          for (; i<rows.length; i++) {
              if (rows[i].id == pointId)
                  break;
          }
          if (i != 0) {
              watchListTable.insertBefore(rows[i], rows[i-1]);
              WatchListDwr.moveUp(pointId.substring(1));
              fixRowFormatting();
          }
      }
      
      function fixRowFormatting() {
          var rows = getElementsByMangoName($("watchListTable"), "watchListRow");
          if (rows.length == 0) {
              show("emptyListMessage");
          }
          else {
              hide("emptyListMessage");
              for (var i=0; i<rows.length; i++) {
                  if (i == 0) {
                      hide(rows[i].id +"BreakRow");
                      hide(rows[i].id +"MoveUp");
                  }
                  else {
                      show(rows[i].id +"BreakRow");
                      if (owner)
                          show(rows[i].id +"MoveUp");
                  }
                      
                  if (i == rows.length - 1)
                      hide(rows[i].id +"MoveDown");
                  else if (owner)
                      show(rows[i].id +"MoveDown");
              }
          }
      }
      
      function showChart(mangoId, event, source) {
    	  if (isMouseLeaveOrEnter(event, source)) {
              // Take the data in the chart textarea and put it into the chart layer div
              $set('p'+ mangoId +'ChartLayer', $get('p'+ mangoId +'Chart'));
              showMenu('p'+ mangoId +'ChartLayer', 4, 12);
    	  }
      }
      
      function hideChart(mangoId, event, source) {
          if (isMouseLeaveOrEnter(event, source))
        	  hideLayer('p'+ mangoId +'ChartLayer');
      }
      
      //
      // Image chart
      //
      function getImageChart() {
          var width = dojo.html.getContentBox($("imageChartDiv")).width - 20;
          startImageFader($("imageChartImg"));
          WatchListDwr.getImageChartData(getChartPointList(), $get("fromYear"), $get("fromMonth"), $get("fromDay"), 
        		  $get("fromHour"), $get("fromMinute"), $get("fromSecond"), $get("fromNone"), $get("toYear"), 
        		  $get("toMonth"), $get("toDay"), $get("toHour"), $get("toMinute"), $get("toSecond"), $get("toNone"), 
        		  width, 350, function(data) {
              $("imageChartDiv").innerHTML = data;
              stopImageFader($("imageChartImg"));
              
              // Make sure the length of the chart doesn't mess up the watch list display. Do async to
              // make sure the rendering gets done.
              setTimeout('dojo.widget.manager.getWidgetById("splitContainer").onResized()', 2000);
          });
      }
      
      function getChartData() {
    	  var pointIds = getChartPointList();
    	  if (pointIds.length == 0)
    		  alert("<fmt:message key="watchlist.noExportables"/>");
    	  else {
              startImageFader($("chartDataImg"));
              WatchListDwr.getChartData(getChartPointList(), $get("fromYear"), $get("fromMonth"), $get("fromDay"), 
                      $get("fromHour"), $get("fromMinute"), $get("fromSecond"), $get("fromNone"), $get("toYear"), 
                      $get("toMonth"), $get("toDay"), $get("toHour"), $get("toMinute"), $get("toSecond"), $get("toNone"), 
                      function(data) {
                  stopImageFader($("chartDataImg"));
                  window.location = "chartExport/watchListData.csv";
              });
    	  }
      }
      
      function getChartPointList() {
          var pointIds = $get("chartCB");
          for (var i=pointIds.length-1; i>=0; i--) {
              if (pointIds[i] == "_TEMPLATE_") {
                  pointIds.splice(i, 1);
              }
          }
          return pointIds;
      }
      
      //
      // Create report
      function createReport() {
          window.location = "reports.shtm?wlid="+ $get("watchListSelect");
      }
    </script>
     <span class="smallTitle"><fmt:message key="landing_home.welcomeToMango"/></span> <!--<tag:help id="welcomeToMango"/>--> <br/><br/>
          
    <table width="100%">
    <tr><td>
      <div dojoType="SplitContainer" orientation="horizontal" sizerWidth="3" activeSizing="true" class="borderDiv"
              widgetId="splitContainer" style="width: 100%; height: 500px;">
        <div dojoType="ContentPane" sizeMin="20" sizeShare="20" style="overflow:auto;padding:2px;">
                <img src="images/hourglass.png" id="loadingImg"/>
                <p> <strong>Mango M2M is an open-source software platform designed for monitoring, control, and automation of various systems and processes. For more information about mango <a href="help.shtm">click here</a></strong></p>
                <p><strong>Mango gives an option to create individual user who can use the system. Various privileges can be assigned to users to grant them the ability to read and alter data and system behaviour. To create a new user <a href="users.shtm">click here</a></strong></p>
            <p><strong>Images such as relevant sensor diagrams can also be included. </strong></p>
           <img src="images/sensor_locations.png" id="sensor_locations"/>
          <div id="treeDiv" style="display:none;"><div dojoType="Tree" widgetId="tree"></div></div>
        </div>
        <div dojoType="ContentPane" sizeMin="50" sizeShare="50" style="overflow:auto; padding:2px 10px 2px 2px;">
          <table cellpadding="0" cellspacing="0" width="100%">
            <tr>
              <td class="smallTitle"><fmt:message key="watchlist.watchlist"/> <tag:help id="watchList"/></td>
              <td align="right">
                <sst:select id="watchListSelect" value="${selectedWatchList}" onchange="watchListChanged()"
                        onmouseover="closeLayers();">
                  <c:forEach items="${watchLists}" var="wl">
                    <sst:option value="${wl.key}">${sst:escapeLessThan(wl.value)}</sst:option>
                  </c:forEach>
                </sst:select>
                
                <div id="wlEditDiv" style="display:inline;" onmouseover="showWatchListEdit()">
                  <tag:img id="wlEditImg" png="pencil" title="watchlist.editListName"/>
                  <div id="wlEdit" style="visibility:hidden;left:0px;top:15px;" class="labelDiv"
                          onmouseout="hideLayer(this)">
                    <fmt:message key="watchlist.newListName"/><br/>
                    <input type="text" id="newWatchListName"
                            onkeypress="if (event.keyCode==13) $('saveWatchListNameLink').onclick();"/>
                    <a class="ptr" id="saveWatchListNameLink" onclick="saveWatchListName()"><fmt:message key="common.save"/></a>
                  </div>
                </div>
                
                <div id="usersEditDiv" style="display:inline;" onmouseover="showWatchListUsers()">
                  <tag:img png="user" title="share.sharing" onmouseover="closeLayers();"/>
                  <div id="usersEdit" style="visibility:hidden;left:0px;top:15px;" class="labelDiv">
                    <tag:sharedUsers doxId="watchListSharing" noUsersKey="share.noWatchlistUsers"
                            closeFunction="hideLayer('usersEdit')"/>
                  </div>
                </div>
                
                <tag:img png="copy" onclick="addWatchList(true)" title="watchlist.copyList" onmouseover="closeLayers();"/>
                <tag:img png="add" onclick="addWatchList(false)" title="watchlist.addNewList" onmouseover="closeLayers();"/>
                <tag:img png="delete" id="watchListDeleteImg" onclick="deleteWatchList()" title="watchlist.deleteList"
                        style="display:none;" onmouseover="closeLayers();"/>
                <tag:img png="report_add" onclick="createReport()" title="watchlist.createReport" onmouseover="closeLayers();"/>
              </td>
            </tr>
          </table>
          <div id="watchListDiv" class="watchListAttr">
            <table style="display:none;">
              <tbody id="p_TEMPLATE_">
                <tr id="p_TEMPLATE_BreakRow"><td class="horzSeparator" colspan="5"></td></tr>
                <tr>
                  <td width="1">
                    <table cellpadding="0" cellspacing="0" class="rowIcons">
                      <tr>
                        <td onmouseover="mango.view.showChange('p'+ getMangoId(this) +'Change', 4, 12);"
                                onmouseout="mango.view.hideChange('p'+ getMangoId(this) +'Change');"
                                id="p_TEMPLATE_ChangeMin" style="display:none;"><img alt="" id="p_TEMPLATE_Changing" 
                                src="images/icon_edit.png"/><div id="p_TEMPLATE_Change" class="labelDiv" 
                                style="visibility:hidden;top:10px;left:1px;" onmouseout="hideLayer(this);">
                          <tag:img png="hourglass" title="common.gettingData"/>
                        </div></td>
                        <td id="p_TEMPLATE_ChartMin" style="display:none;" onmouseover="showChart(getMangoId(this), event, this);"
                                onmouseout="hideChart(getMangoId(this), event, this);"><img alt="" 
                                src="images/icon_chart.png"/><div id="p_TEMPLATE_ChartLayer" class="labelDiv" 
                                style="visibility:hidden;top:0;left:0;"></div><textarea
                                style="display:none;" id="p_TEMPLATE_Chart"><tag:img png="hourglass"
                                title="common.gettingData"/></textarea></td>
                      </tr>
                    </table>
                  </td>
                  <td id="p_TEMPLATE_Name" style="font-weight:bold"></td>
                  <td id="p_TEMPLATE_Value" align="center"><img src="images/hourglass.png"/></td>
                  <td id="p_TEMPLATE_Time" align="center"></td>
                  <td style="width:1px; white-space:nowrap;">
                    <input type="checkbox" name="chartCB" id="p_TEMPLATE_ChartCB" value="_TEMPLATE_" checked="checked"
                            title="<fmt:message key="watchlist.consolidatedChart"/>"/>
                    <tag:img png="icon_comp" title="watchlist.pointDetails"
                            onclick="window.location='data_point_details.shtm?dpid='+ getMangoId(this)"/>
                    <tag:img png="arrow_up_thin" id="p_TEMPLATE_MoveUp" title="watchlist.moveUp" style="display:none;"
                            onclick="moveRowUp('p'+ getMangoId(this));"/><tag:img png="arrow_down_thin"
                            id="p_TEMPLATE_MoveDown" title="watchlist.moveDown" style="display:none;"
                            onclick="moveRowDown('p'+ getMangoId(this));"/>
                    <tag:img id="p_TEMPLATE_Delete" png="bullet_delete" title="watchlist.delete" style="display:none;"
                            onclick="removeFromWatchList(getMangoId(this))"/>
                  </td>
                </tr>
                <tr><td colspan="5" style="padding-left:16px;" id="p_TEMPLATE_Messages"></td></tr>
              </tbody>
            </table>
            <table id="watchListTable" width="100%"></table>
            <div id="emptyListMessage" style="color:#888888;padding:10px;text-align:center;">
              <fmt:message key="watchlist.emptyList"/>
            </div>
          </div>
        </div>
      </div>
    </td></tr>
    
    
    <tr><td>
      <div class="borderDiv" style="width: 100%;">
        <table width="100%">
          <tr>
            <td class="smallTitle"><fmt:message key="watchlist.chart"/> <tag:help id="watchListCharts"/></td>
            <td align="right"><tag:dateRange/></td>
            <td>
              <tag:img id="imageChartImg" png="control_play_blue" title="watchlist.imageChartButton"
                      onclick="getImageChart()"/>
              <tag:img id="chartDataImg" png="bullet_down" title="watchlist.chartDataButton"
                      onclick="getChartData()"/>
            </td>
          </tr>
          <tr><td colspan="3" id="imageChartDiv"></td></tr>
        </table>
      </div>
    </td></tr>
    
    </table>
  </jsp:body>
</tag:page>
