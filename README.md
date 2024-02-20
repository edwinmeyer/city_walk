city_walk
=========

> city_walk.rb -- A Ruby 1.9.3 demo program which traverses the course of a walking event.

> <b>Usage:</b> <i>ruby city_walk.rb < cw_input.txt</i> <br>

> Substitute 'cw_input-inf.txt' or 'cw_input-oob.txt' for an infinite loop or out-of-bounds traversal, respectively.

> <b>Street grid:</b>
> This city has a rectilinear street grid where lettered north-south avenues start with "A" at the eastern city limits and increase going west, and numbered east-west streets start with "1" at the southern city limits and increase going north. <br>
> Avenue "Z" marks the western city limit, and Street "199" marks the northern city limit.

> <b>Input:</b> <br>
> city_walk.rb reads its input from STDIN. The input consists of one or more lines of comma-delimited text of the format: <br>
> \<intersection\>,\<checkpoint type\>

> An intersection is specified as \<street number\>&\<avenue letter\>. The program outputs intersections in this format; however the input may also provide the avenue letter first.

> checkpoint type is one of the following: <br>
> start_east, start_west, start_north, start_south - start point of the walk with indicated initial direction. <br>
> In the case of multiple start checkpoints, the latest encountered is used. <br>
> end -- The walk ends at this checkpoint <br>
> go_north, go_south, go_west, go_east -- continue in the indicated direction from this checkpoint. <br>
> turn_right, turn_left -- turn right or left at this checkpoint. <br>
> go_back -- reverse direction at this checkpoint. <br>
> The input can provide the checkpoint lines definition in an arbitrary order.

> <b>Output:</b> <br>
> The output consists of lines listing all encountered checkpoints written to STDOUT, Each line contains the intersection, the checkpoint type, the direction to be followed leaving the checkpoint, and the cumulative number of blocks traversed at that point. <br>
> The first line is that of the "start" checkpoint (cumulative block count 0), and the last line is that of the "end" checkpoint (direction "stop"). There are two possible course planning errors which prevent the end point from being reached: <br>
>   1) going beyond the course boundaries, and <br>
>   2) a non-terminating course loop. These errors are written as the last line of output below that for the last encountered checkpoint as "out of bounds" or "infinite loop". The non-terminating loop error must be reported immediately after the first repeated checkpoint is output.

> <b>Implmentation:</b> <br>
> The classes which implement the city_walk course traversal program are: <br>
> Grid -- contains the grid specification. <br>
> GridLoader -- loads the Grid from the input stream. <br>
> Position -- contains an intersection and the grid boundaries. <br>
> Walker -- traverses the grid and returns the cumulative distance travelled. <br>
> Checkpoint and its subclasses (e.g. StartEast, GoNorth, TurnLeft, etc.) -- Specify the new direction of the walker out of the checkpoint. <br>
> TraversalHistory -- detects loops by recording traversals of an intersection in a particular direction. <br>
