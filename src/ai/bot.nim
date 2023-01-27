# #alpha beta search algorithm
# proc alphaBeta(node, depth: int, alpha: int, beta: int, maximizingPlayer: bool) =
#     if depth = 0 or node is a terminal node then
#         return the heuristic value of node
#     if maximizingPlayer then
#         value := -infinity
#         for each child of node do
#             value := max(value, alphaBeta(child, depth - 1, alpha, beta, FALSE))
#             alpha := max(alpha, value)
#             if beta <= alpha then
#                 break (* beta cut-off *)
#         return value
#     else
#         value := +infinity
#         for each child of node do
#             value := min(value, alphaBeta(child, depth - 1, alpha, beta, TRUE))
#             beta := min(beta, value)
#             if beta <= alpha then
#                 break (* alpha cut-off *)
#         return value