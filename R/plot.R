#' Plot an admixture graph.
#' 
#' This is a basic drawing routine for visualising the graph. For publication
#' quality graphs a lot more tweaking is probably needed.
#' 
#' @param x The admixture graph.
#' @param ordered_leaves The leaf-nodes in the left to right order they should
#'   be drawn. I don't have a good algorithm for figuring out that order so for
#'   now it is required as a function argument.
#' @param show_admixture_labels A flag determining if the plot should include
#'   the names of admixture proportions.
#' @param show_inner_node_labels A flat determining if the plot should include
#'   the names of inner nodes.
#'   
#' @param ... Additional plotting options
#'   
#' @export
plot.agraph <- function(x, 
                        ordered_leaves = NULL,
                        show_admixture_labels = FALSE,
                        show_inner_node_labels = FALSE,
                        ...) {
  
  graph <- x
  
  if (is.null(ordered_leaves))
    ordered_leaves <- graph$leaves

  dfs <- function(node, basis, step) {
    result <- rep(NA, length(graph$nodes))
    names(result) <- graph$nodes

    dfs_ <- function(node) {
      children <- which(graph$children[node,])
      if (length(children) == 0) {
        result[node] <<- basis(node)
      } else {
        result[node] <<- step(vapply(children, dfs_, numeric(1)))
      }
    }
    dfs_(node)
    result
  }

  no_parents <- function(node) length(which(graph$parents[node, ]))
  roots <- which(Map(no_parents, graph$nodes) == 0)
  if (length(roots) > 1) stop("Don't know how to handle more than one root")
  root <- roots[1]
  ypos <- dfs(root, basis = function(x) 0.0, step = function(x) max(x) + 1.0)

  leaf_index <- function(n) {
    result <- which(graph$nodes[n] == ordered_leaves)
    if (length(result) != 1) stop("Unexpected number of matching nodes")
    result
  }
  left_x  <- dfs(root, basis = leaf_index, step = min)
  right_x <- dfs(root, basis = leaf_index, step = max)
  xpos <- left_x + (right_x - left_x) / 2.0

  # Start the actual drawing of the graph...
  plot(xpos, ypos, type = "n", axes = FALSE, frame.plot = FALSE,
       xlab = "", ylab = "", ylim = c(-1, max(ypos) + 0.5), ...)

  for (node in graph$nodes) {
    parents <- graph$nodes[graph$parents[node, ]]
    if (length(parents) == 1) {
      lines(c(xpos[node],xpos[parents]), c(ypos[node], ypos[parents]))

    } else if (length(parents) == 2) {
      break_y <- ypos[node]
      break_x_left <- xpos[node] - 0.3
      break_x_right <- xpos[node] + 0.3
      
      if (xpos[parents[1]] < xpos[parents[2]]) {
        lines(c(xpos[parents[1]], break_x_left), c(ypos[parents[1]], break_y))
        lines(c(xpos[parents[2]], break_x_right), c(ypos[parents[2]], break_y))  
      } else {
        lines(c(xpos[parents[2]], break_x_left), c(ypos[parents[2]], break_y))
        lines(c(xpos[parents[1]], break_x_right), c(ypos[parents[1]], break_y))
      }
      
      
      segments(break_x_left, break_y, xpos[node], ypos[node], col = "red")
      segments(break_x_right, break_y, xpos[node], ypos[node], col = "red")
      
      if (show_admixture_labels) {
        if (xpos[parents[1]] < xpos[parents[2]]) {
          text(break_x_left, break_y, graph$probs[parents[[1]], node],
               cex = 0.5, pos = 1, col = "red", offset = 0.1)
          text(break_x_right, break_y, graph$probs[parents[[2]], node],
               cex = 0.5, pos = 1, col = "red", offset = 0.1)
        } else {
          text(break_x_left, break_y, graph$probs[parents[[2]], node],
               cex = 0.5, pos = 1, col = "red", offset = 0.1)
          text(break_x_right, break_y, graph$probs[parents[[1]], node],
               cex = 0.5, pos = 1, col = "red", offset = 0.1)          
        }
      }
    }
  }

  is_inner <- Vectorize(function(n) sum(graph$children[n, ]) > 0)
  inner_nodes <- which(is_inner(graph$nodes))
  leaves <- which(!is_inner(graph$nodes))

  if (show_inner_node_labels) {
    text(xpos[inner_nodes], ypos[inner_nodes], 
         labels = graph$nodes[inner_nodes], cex = 0.6, col = "blue", pos = 3)
  }
  text(xpos[leaves], ypos[leaves], labels = graph$nodes[leaves], 
       cex = 0.7, col = "black", pos = 1)

  invisible()
}
