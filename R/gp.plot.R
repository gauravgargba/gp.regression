# Copyright (C) 2013 Philipp Benner
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

library("ggplot2")
library("gridExtra")
library("scales")

plot.gp.1d <- function(gp, x, main="",
                       xlabel=NULL, ylabel=NULL, alpha=0.5,
                       col.mean="red", plot.mean = TRUE, plot.variance=TRUE,
                       plot.scatter=TRUE, covariates=NULL, ...)
{
    result <- summarize(gp, x, ...)

    p <- ggplot(data.frame(x = x[,covariates], mean = result$mean), aes(x=x))
    # add labels and title
    p <- p + xlab(xlabel)
    p <- p + ylab(ylabel)
    p <- p + ggtitle(main)

    # first add the scatter plot
    if (plot.scatter && !is.null(gp$xp) && dim(gp$yp)[2] == 1) {
        p <- p + geom_point(data=data.frame(x=gp$xp[,covariates], y=gp$yp),
                            aes(x = x, y = y))
    }
    # and the variance
    if (plot.variance && !is.null(result$variance)) {
        p <- p + geom_ribbon(data=data.frame(x=x[,covariates],
                                             ymin=result$mean-2*sqrt(result$variance),
                                             ymax=result$mean+2*sqrt(result$variance)),
                             aes(ymin=ymin, ymax=ymax),
                             col="gray", fill="black",
                             alpha=alpha)
    }
    # on top the regression line
    if (plot.mean) {
        p <- p + geom_line(aes(y=mean), col=col.mean)
    }
    return (p)
}

plot.gp.2d <- function(gp, x, plot.variance=TRUE, plot.scatter=FALSE,
                       low=muted("green"), mid="white", high=muted("red"),
                       midpoint=NULL,
                       covariates=NULL, ...)
{
    # initialize all plot objects
    p1 <- NULL
    p2 <- NULL
    # compute expectation and variance
    result <- summarize(gp, x, ...)
    # maximum and minimum for plotting
    limits <- c(min(result$mean), max(result$mean))
    # midpoint for the color gradient
    midpoint <- sum(limits)/2.0

    # first, plot the expectation
    p1 <- ggplot(data = data.frame(x = x[,covariates[1]], y = x[,covariates[2]], z = result$mean),
                 aes_string(x = "x", y = "y", z = "z")) +
        geom_tile(aes_string(fill="z"), limits=limits) +
        stat_contour() +
        scale_fill_gradient2(limits=limits, low=low, mid=mid, high=high, midpoint=midpoint) +
        ggtitle("Expected value")

    if (plot.scatter && !is.null(gp$xp) && dim(gp$yp)[2] == 1) {
        p1 <- p1 + geom_point(data=data.frame(x=gp$xp[,covariates[1]], y=gp$xp[,covariates[2]], z = gp$yp),
                              aes(x = x, y = y, colour = z))
    }

    # plot varience only if plot.variance is TRUE
    if (plot.variance) {
        p2 <- ggplot(data = data.frame(x = x[,covariates[1]], y = x[,covariates[2]], z = result$variance),
                     aes_string(x = "x", y = "y", z = "z")) +
            geom_tile(aes_string(fill="z")) +
            stat_contour() +
            scale_fill_gradient(low=mid, high=high) +
            ggtitle("Variance")
    }
    # use different grids depending on what plots are available
    if (!is.null(p2)) {
        grid.arrange(p1, p2, ncol=2)
    }
    else {
        grid.arrange(p1, ncol=1)
    }
    # return a list of all plot objects
    return (invisible(list(p1=p1, p2=p2)))
}

#' Plot a Gaussian process
#'
#' @param x Gaussian process
#' @param y positions where to evaluate the Gaussian process
#' @param covariates plot only the given covariates
#' @param ... arguments to be passed to methods
#' @method plot gp
#' @export

plot.gp <- function(x, y, covariates=NULL, ...)
{
    # rename variables
    gp <- x
    x  <- as.matrix(y)

    if (is.null(covariates)) {
        covariates <- 1:dim(gp)
    }

    if (length(covariates) == 1) {
        plot.gp.1d(gp, x, covariates=covariates, ...)
    }
    else if (length(covariates) == 2) {
        plot.gp.2d(gp, x, covariates=covariates, ...)
    }
    else {
        stop("Gaussian process has invalid dimension.")
    }
}

#' Plot a heteroscedastic Gaussian process
#'
#' @param x heteroscedastic Gaussian process
#' @param y positions where to evaluate the Gaussian process
#' @param alpha transparency of confidence intervals
#' @param ... arguments to be passed to methods
#' @method plot gp.heteroscedastic
#' @export

plot.gp.heteroscedastic <- function(x, y, alpha=0.3, ...)
{
    # rename variables
    model <- x
    x     <- as.matrix(y)

    result <- summarize(model, x)

    p <- plot(model$gp, x, ...)
    p <- p + geom_ribbon(data=data.frame(x=x,
                                         ymin=result$mean-2*sqrt(result$variance),
                                         ymax=result$mean+2*sqrt(result$variance)),
                         aes(ymin=ymin, ymax=ymax),
                         alpha=alpha, fill="red")

    return (p)
}
