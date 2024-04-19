package com.serotonin.mango.vo.report;

import java.io.IOException;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;
import java.io.Serializable;

import com.serotonin.util.SerializationHelper;

public class ReportPointVO implements Serializable {
    private int pointId;
    private String colour;
    private boolean consolidatedChart;
    private boolean ChartType;
    private String Title;
    private String XAxis;
    private String YAxis;
    private int YReference;


    public int getPointId() {
        return pointId;
    }

    public void setPointId(int pointId) {
        this.pointId = pointId;
    }

    public String getColour() {
        return colour;
    }

    public void setColour(String colour) {
        this.colour = colour;
    }

    public boolean isConsolidatedChart() {
        return consolidatedChart;
    }

    public void setConsolidatedChart(boolean consolidatedChart) {
        this.consolidatedChart = consolidatedChart;
    }

    public boolean isChartType() {
        return ChartType;
    }

    public void setChartType(boolean ChartType) {
        this.ChartType = ChartType;
    }

    public String getTitle() {
        return Title;
    }

    public void setTitle(String Title) {
        this.Title = Title;
    }

    public String getXAxis() {
        return XAxis;
    }

    public void setXaxis(String XAxis) {
        this.XAxis = XAxis;
    }

    public String getYAxis() {
        return YAxis;
    }

    public void setYaxis(String YAxis) {
        this.YAxis = YAxis;
    }

    public int getYReference() {
        return YReference;
    }

    public void setYReference(int YReference) {
        this.YReference = YReference;
    }
}