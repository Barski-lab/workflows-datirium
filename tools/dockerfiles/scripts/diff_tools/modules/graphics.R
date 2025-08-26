
import("EnhancedVolcano", attach=FALSE)
import("magrittr", `%>%`, attach=TRUE)

export(
    "get_theme",
    "volcano_plot"
)

get_theme <- function(theme){
    return (
        switch(
            theme,
            "gray"     = ggplot2::theme_gray(),
            "bw"       = ggplot2::theme_bw(),
            "linedraw" = ggplot2::theme_linedraw(),
            "light"    = ggplot2::theme_light(),
            "dark"     = ggplot2::theme_dark(),
            "minimal"  = ggplot2::theme_minimal(),
            "classic"  = ggplot2::theme_classic(),
            "void"     = ggplot2::theme_void()
        )
    )
}

volcano_plot <- function(
    data, rootname,
    x_axis, y_axis,
    x_cutoff, y_cutoff,
    x_label, y_label,
    plot_title, plot_subtitle,
    caption,
    features=NULL,
    size_by=NULL, size_from=NULL, color_by=NULL, alpha_by=NULL,
    overlay_by=NULL, overlay_from=NULL, overlay_color_by=NULL, overlay_alpha=1,   # works only if size_by provided
    label_column="gene",
    x_padding=0.25, y_padding=0.25,
    theme="classic",
    pdf=FALSE,
    width=1200, height=800, resolution=100
){
    base::tryCatch(
        expr = {
            plot <- EnhancedVolcano::EnhancedVolcano(
                        data,
                        x=x_axis,
                        y=y_axis,
                        lab=data[,label_column],
                        FCcutoff=x_cutoff,
                        pCutoff=y_cutoff,
                        xlab=x_label,
                        ylab=y_label,
                        xlim=c(
                            min(data[[x_axis]], na.rm=TRUE) - x_padding,
                            max(data[[x_axis]], na.rm=TRUE) + x_padding
                        ),
                        ylim=c(0, max(-log10(data[[y_axis]]), na.rm=TRUE) + y_padding),
                        selectLab=features,
                        title=plot_title,
                        subtitle=plot_subtitle,
                        caption=caption,
                        labSize=4,
                        labFace="bold",
                        labCol="black",
                        colAlpha = if (!is.null(alpha_by))
                                       data[[alpha_by]]
                                   else 0.5,
                        shape=16,
                        col=c("grey30", "forestgreen", "royalblue", "red"),                                # will be ignored if colCustom was provided
                        colCustom = if (!is.null(color_by))
                                        stats::setNames(data[[color_by]], data[[color_by]]) 
                                    else
                                        NULL,
                        pointSize = if (!is.null(size_by))
                                        scales::rescale(
                                            data[[size_by]],
                                            from = if (!is.null(size_from) && length(size_from) == 2)
                                                       size_from
                                                   else
                                                       range(data[[size_by]], na.rm=TRUE, finite=TRUE),    # this is default value in the rescale function
                                            to=c(1, 5)
                                        )
                                    else 2,
                        drawConnectors=TRUE,
                        arrowheads=FALSE,
                        widthConnectors=0.25
                    ) +
                    get_theme(theme) +
                    ggplot2::theme(
                        legend.position="none",
                        plot.subtitle=ggplot2::element_text(size=8, face="italic", color="gray30")
                    )

            if (max(-log10(data[[y_axis]]), na.rm=TRUE) >= 50){
                plot <- plot + ggplot2::scale_y_log10() +
                        ggplot2::annotation_logticks(sides="l", alpha=0.3)
            }

            if(!is.null(overlay_by) && !is.null(size_by)){                                                 # bigger dots will be always behind the smaller ones
                plot <- plot +
                        ggplot2::geom_point(                                                               # layer with the smaller than size_by dots
                            shape=16,
                            colour = if (!is.null(overlay_color_by))
                                        data[[overlay_color_by]]
                                    else
                                        "black",
                            alpha=base::ifelse(                                                            # dots with 0 size or bigger than original dots are not shown
                                      data[[overlay_by]] != 0 & data[[overlay_by]] <= data[[size_by]],
                                      overlay_alpha,
                                      0
                            ),
                            size=scales::rescale(
                                data[[overlay_by]],
                                from = if (!is.null(overlay_from) && length(overlay_from) == 2)
                                        overlay_from
                                    else
                                        range(data[[overlay_by]], na.rm=TRUE, finite=TRUE),
                                to=c(1, 5)
                            )
                        ) +
                        ggplot2::geom_point(                                                               # layer with the bigger than size_by dots
                            shape=16,
                            colour = if (!is.null(overlay_color_by))
                                        data[[overlay_color_by]]
                                    else
                                        "black",
                            alpha=base::ifelse(
                                      data[[overlay_by]] != 0 & data[[overlay_by]] > data[[size_by]],
                                      overlay_alpha,
                                      0
                            ),
                            size=scales::rescale(
                                data[[overlay_by]],
                                from = if (!is.null(overlay_from) && length(overlay_from) == 2)
                                        overlay_from
                                    else
                                        range(data[[overlay_by]], na.rm=TRUE, finite=TRUE),
                                to=c(1, 5)
                            )
                        )
                plot$layers <- c(                                                                          # need to put the big dots behind the small ones
                    plot$layers[length(plot$layers)],
                    plot$layers[1],
                    plot$layers[length(plot$layers) - 1],
                    plot$layers[2:(length(plot$layers)-2)]
                )
            }

            grDevices::png(filename=base::paste(rootname, ".png", sep=""), width=width, height=height, res=resolution)
            base::suppressMessages(base::print(plot))
            grDevices::dev.off()

            if (pdf) {
                grDevices::pdf(file=base::paste(rootname, ".pdf", sep=""), width=round(width/resolution), height=round(height/resolution))
                base::suppressMessages(base::print(plot))
                grDevices::dev.off()
            }

            if (knitr::is_html_output()){
                knitr::opts_chunk$set(
                    fig.width=round(width/resolution),
                    fig.height=round(height/resolution),
                    dpi=resolution
                )
                base::plot(plot)
            }

            base::print(base::paste("Export volcano plot to ", rootname, ".(png/pdf)", sep=""))
        },
        error = function(e){
            base::tryCatch(expr={grDevices::dev.off()}, error=function(e){})
            base::print(base::paste("Failed to export volcano plot to ", rootname, ".(png/pdf) with error - ", e, sep=""))
        }
    )
}