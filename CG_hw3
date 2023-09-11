#!/usr/bin/env python3

import argparse
import math
import sys


class Coordinates:
    def __init__(self):
        self.x1 = 0
        self.y1 = 0
        self.x2 = 0
        self.y2 = 0

    # uses the current line to re-assign attributes
    def _set_points(self, line):
        if "Line" in line:
            self.x1, self.y1 = float(line[0]), float(line[1])
            self.x2, self.y2 = float(line[2]), float(line[3])
        elif "moveto" in line or "lineto" in line:
            self.x1, self.y1 = float(line[0]), float(line[1])
        elif len(line) == 2:
            self.x1, self.y1 = float(line[0]), float(line[1])

class FileIO:
    def __init__(self, path):
        self.path = path
    
    def write_pbm(self, lines, args):
        new_line = 1
        sys.stdout.write(f"P1\n# {args.file[:-3]}.pbm\n{501} {501}\n")
        lines.reverse()
        for row in lines:
            for col in row:
                if new_line == 70:
                    print(col, end="\n")
                    new_line = 1
                    continue
                print(col, end=" ")
                new_line += 1

    # take a list of lines, write them to stdout in .ps form
    def write_ps(self, lines, args):
        x_size = args.upper_boundx - args.lower_boundx + 1
        y_size = args.upper_boundy - args.lower_boundy + 1

        is_moveto = True

        sys.stdout.write(f"%%BeginSetup\n   << /PageSize [{x_size} {y_size}] >> setpagedevice\n%%EndSetup\n\n%%%BEGIN")
        for line in lines:
            if "stroke" not in line:
                x = line[0] - args.lower_boundx
                y = line[1] - args.lower_boundy
            #     if x < 0:
            #         x = 0
            #     if y < 0:
            #         y = 0
            if "Line" in line:
                sys.stdout.write(f"\n{line[0]-args.lower_boundx} {line[1]-args.lower_boundy} moveto\n{line[2]-args.lower_boundx} {line[3]-args.lower_boundy} lineto\nstroke")
            elif "moveto" in line or "lineto" in line:
                sys.stdout.write(f"\n{line[0]-args.lower_boundx} {line[1]-args.lower_boundy} {line[2]}")
            elif "stroke" in line:
                sys.stdout.write(f"\n{line[0]}")
                is_moveto = True
            else:
                if is_moveto:
                    sys.stdout.write(f"\n{x} {y} moveto")
                    is_moveto = False
                else:
                    sys.stdout.write(f"\n{x} {y} lineto")
        sys.stdout.write(f"\n%%%END\n")

    # take a .ps file, parse it into a 2d array
    def read(self):
        with open(self.path) as file:
            commands = self._find_meaningful_lines([line.rstrip() for line in file if line != "\n"])
        return self._split_lines(commands)
    
    # splites the line so each coordinate is its own element
    def _split_lines(self, commands):
        organized = [element.split() for element in commands]
        return organized

    # only keeps lines after %%%BEGIN and before %%%END
    def _find_meaningful_lines(self, commands):
        meaningless = True
        meaningful_lines = []
        for element in commands:
            if meaningless:
                if f"%%%BEGIN" in element:
                    meaningless = False
            else:
                if f"%%%END" in element:
                    break
                meaningful_lines.append(element)
        return meaningful_lines

class Transformer(Coordinates):
    def __init__(self, lines, args):
        super().__init__()
        self.lines = lines
        self.args = args

    # create a new list of transformed lines
    def transform_lines(self):
        new_lines = []
        for line in self.lines:
            if "stroke" in line:
                new_lines.append(line)
            else:
                self._set_points(line)
                self._scale()
                self._rotate()
                self._translate()
                if "Line" in line:
                    new_lines.append([self.x1, self.y1, self.x2, self.y2, line[4]])
                elif "moveto" in line or "lineto" in line:
                    new_lines.append([self.x1, self.y1, line[2]])
        return new_lines

    def _scale(self, x_scale = None, y_scale = None):
        if x_scale is None and y_scale is None:
            self.x1 = self.x1 * self.args.scaling_factor
            self.y1 =  self.y1 * self.args.scaling_factor

            self.x2 = self.x2 * self.args.scaling_factor
            self.y2 =  self.y2 * self.args.scaling_factor
        else:
            self.x1 = self.x1 * x_scale
            self.y1 = self.y1 * y_scale

    def _rotate(self):
        phi = self.args.ccr * math.pi / 180
        x1 = self.x1 * math.cos(phi) - self.y1 * math.sin(phi)
        y1 = self.x1 * math.sin(phi) + self.y1 * math.cos(phi)
        x2 = self.x2 * math.cos(phi) - self.y2 * math.sin(phi)
        y2 = self.x2 * math.sin(phi) + self.y2 * math.cos(phi)

        self.x1 = x1
        self.y1 = y1
        self.x2 = x2
        self.y2 = y2
    
    def _translate(self, x_dim = None, y_dim = None):
        if x_dim is None and y_dim is None:
            self.x1 += self.args.x_dim
            self.y1 += self.args.y_dim

            self.x2 += self.args.x_dim
            self.y2 += self.args.y_dim
        else:
            self.x1 += x_dim
            self.y1 += y_dim
            

class Clip(Coordinates):
    def __init__(self, lines, args, transformer: Transformer):
        super().__init__()
        self.lines = lines
        self.args = args
        self.transformer = transformer
        self.inside = 0 # 0000
        self.left = 1   # 0001
        self.right = 2  # 0010
        self.bottom = 4 # 0100
        self.top = 8    # 1000
        self.x_min = self.args.lower_boundx
        self.y_min = self.args.lower_boundy
        self.x_max = self.args.upper_boundx
        self.y_max = self.args.upper_boundy
        self.u_min = self.args.lb_viewportx
        self.v_min = self.args.lb_viewporty
        self.u_max = self.args.ub_viewportx
        self.v_max = self.args.ub_viewporty

    def world_to_viewport(self, polygons):
        s_x = (self.u_max - self.u_min) / (self.x_max - self.x_min)
        s_y = (self.v_max - self.v_min) / (self.y_max - self.y_min)
        viewport_polygon = []
        for polygon in polygons:
            for line in polygon:
                if "stroke" in line:
                    viewport_polygon.append(line)
                else:
                    self.transformer._set_points(line)
                    self.transformer._translate(self.u_min, self.v_min)
                    self.transformer._scale(s_x, s_y)
                    self.transformer._translate(-self.x_min, -self.y_min)
                    viewport_polygon.append([round(self.transformer.x1), round(self.transformer.y1)])
        return viewport_polygon

    def _set_scan_line_edge(self, y):
        return [self.x_min, y, self.x_max, y]

    def _sort_intersections(self, scan_line_edge, edges, polygon):
        intersections = []
        for edge in edges:
            intersection = self._compute_intersection(polygon[edge[0]], polygon[edge[1]], scan_line_edge)
            intersections.append(intersection[0])
        intersections.sort(key=lambda x: x)
        return intersections

    def _update_parity_bit(self, scan_fill, parity_bit):
        new_parity_bit = parity_bit
        for row in range(len(parity_bit)):
            if scan_fill[row]:
                # grab each pair of fill intersections and fill that range with 1's in that row
                for i in range(0, len(scan_fill[row]), 2):
                    for col in range(math.ceil(scan_fill[row][i]), math.floor(scan_fill[row][i+1])):   
                        try:
                            new_parity_bit[row][col] = 1
                        except IndexError:
                            continue
            else:
                # previous polygon has filled this line
                if 1 not in parity_bit[row]:
                    # fill empty
                    empty = [0]*(len(parity_bit[0]))
                    new_parity_bit[row] = empty
        return new_parity_bit


    def scan_fill(self, polygons):
        organized_polygons = self._prepare_polygons(polygons)
        parity_bit = [[0]*(501) for _ in range(501)]
        for polygon in organized_polygons:
            # returns every y that x amount of edges intersects with it
            scan_fill = self._polygon_scan_fill(polygon)
            # update scan_fill with sorted intersections
            for scan_line, edges in scan_fill.items():
                scan_line_edge = self._set_scan_line_edge(scan_line)
                sorted_intersections = self._sort_intersections(scan_line_edge, edges, polygon)
                scan_fill[scan_line] = sorted_intersections
            parity_bit = self._update_parity_bit(scan_fill, parity_bit)
        return parity_bit
            
    def _polygon_scan_fill(self, polygon):
        scan_line_ys = {}
        for y in range(501):
            edges = []
            for index, line in enumerate(polygon):
                if index+1 < len(polygon) and ("stroke" not in line and "stroke" not in polygon[index+1]):
                    v1 = [line[0], line[1]]
                    v2 = [polygon[index+1][0], polygon[index+1][1]] 
                    y_min = min(v1[1], v2[1])
                    y_max = max(v1[1], v2[1])
                    is_horizontal = y_min - y_max
                    if is_horizontal == 0 or y == y_max:
                        continue
                    if y_min <= y and y < y_max:
                        edges.append([index, index+1])
            scan_line_ys[y] = edges
        return scan_line_ys

    def sutherland_hodgman_clipping(self):
        polygons = self._prepare_polygons(self.lines)
        clipped_polygons = []
        for polygon in polygons:
            clipped_polygons.append(self._single_sutherland_hodgman_clipping(polygon))
        return clipped_polygons

    def _single_sutherland_hodgman_clipping(self, polygon):                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          
        edges = self._set_edges(self.x_min, self.y_min, self.x_max, self.y_max)
        p = polygon
        finalEdgeIndex = 0
        all_outside = 1
        vertices = len(p) - 1
        # [[left], [bottom], [right], [top]]
        for edge in edges:
            clipped_polygon = []
            for index, line in enumerate(p):
                if all_outside == vertices:
                    return []
                elif "stroke" in line:
                    clipped_polygon.append(line)
                    finalEdgeIndex += 1
                elif index+1 < len(p):
                    if "stroke" in p[index+1]:
                        clipped_polygon.append(clipped_polygon[finalEdgeIndex])
                        finalEdgeIndex = index+1
                    else:
                        v1 = [line[0], line[1]]
                        v2 = [p[index+1][0], p[index+1][1]]

                        is_v1_inside = self._is_inside(v1, edge)
                        is_v2_inside = self._is_inside(v2, edge)

                        # both in
                        if is_v1_inside and is_v2_inside:
                            clipped_polygon.append(v2)
                        # both out
                        elif not is_v1_inside and not is_v2_inside:
                            all_outside += 1
                        # v1 in v2 out
                        elif is_v1_inside is True and is_v2_inside is False:
                            inside_outside = self._compute_intersection(v1, v2, edge)
                            clipped_polygon.append(inside_outside)
                        # v1 out v2 in
                        elif is_v1_inside is False and is_v2_inside is True:
                            outside_inside = self._compute_intersection(v1, v2, edge)
                            clipped_polygon.append(outside_inside)
                            clipped_polygon.append(v2)
            p = clipped_polygon
            finalEdgeIndex = 0
        return clipped_polygon

    # sees which lines needs to be clipped and re-calculates coordinates
    def cohen_sutherland_clipping(self):
        clipped_lines = []
        for line in self.lines:
            self._set_points(line)
            x = 0
            y = 0

            p1_code = self._find_code(self.x1, self.y1)
            p2_code = self._find_code(self.x2, self.y2)

            # both in
            if p1_code == 0 and p2_code == 0:
                clipped_lines.append([self.x1, self.y1, self.x2, self.y2, "Line"])
            # both out
            elif (p1_code & p2_code) != 0:
                continue
            else:
                if p1_code == 0:
                    out_code = p2_code
                else:
                    out_code = p1_code

                if out_code == self.left:
                    x = self.x_min
                    y = (self.x_min - self.x1)/(self.x2 - self.x1) * (self.y2 - self.y1) + self.y1
                elif out_code == self.right:
                    x = self.x_max
                    y = (self.x_max - self.x1)/(self.x2 - self.x1) * (self.y2 - self.y1) + self.y1
                elif out_code == self.bottom:
                    y = self.y_min
                    x = (self.y_min - self.y1)/(self.y2 - self.y1) * (self.x2 - self.x1) + self.x1
                elif out_code == self.top:
                    y = self.y_max
                    x = (self.y_max - self.y1)/(self.y2 - self.y1) * (self.x2 - self.x1) + self.x1

                if out_code == p1_code:
                    self.x1 = x
                    self.y1 = y 
                else:
                    self.x2 = x
                    self.y2 = y 
                clipped_lines.append([self.x1, self.y1, self.x2, self.y2, "Line"])
        return clipped_lines

    # calculates the binary value of clipped lines
    def _find_code(self, x, y):
        code = self.inside
        if x < self.x_min:
            code |= self.left
        elif x > self.x_max:
            code |= self.right
        if y < self.y_min:
            code |= self.bottom
        elif y > self.y_max:
            code |= self.top
        return code

    # vertex points: 
    #       x = vertex[0]
    #       y = vertex[1]
    # edge points:
    #   A:
    #       x = edge[0]
    #       y = edge[1]  
    #   B:
    #       x = edge[2]
    #       y = edge[3]
    # vertices are given in counter-clockwise order so "inside" is on the left of the edge
    def _is_inside(self, vertex, edge):
        c = (vertex[0] - edge[0]) * (edge[3] - edge[1]) - (vertex[1] - edge[1]) * (edge[2] - edge[0])
        if "right" in edge or "bottom" in edge:
            c *= -1
        # in/left of line
        if c > 0:
            return True
        # out/right of line
        if c < 0:
            return False
        # on edge
        if c == 0:
            return False

    def _compute_intersection(self, v1, v2, edge):
        new_vertex = []
        x1, y1 = v1[0], v1[1]
        x2, y2 = v2[0], v2[1]
        x3, y3 = edge[0], edge[1]
        x4, y4 = edge[2], edge[3]

        x = ( (x1*y2 - y1*x2) * (x3 - x4) - (x1 - x2) * (x3*y4 - y3*x4) ) / ( (x1 - x2) * (y3 - y4) - (y1 - y2) * (x3 - x4) )
        y = ( (x1*y2 - y1*x2) * (y3 - y4) - (y1 - y2) * (x3*y4 - y3*x4) ) / ( (x1 - x2) * (y3 - y4) - (y1 - y2) * (x3 - x4) )
        new_vertex.append(x)
        new_vertex.append(y)

        return new_vertex

    def _set_edges(self, x_min, y_min, x_max, y_max):
        edges = []
        # right
        edges.append([x_max, y_min, x_max, y_max, "right"])
        # bottom
        edges.append([x_min, y_min, x_max, y_min, "bottom"])
        # left
        edges.append([x_min, y_min, x_min, y_max, "left"])
        # top
        edges.append([x_min, y_max, x_max, y_max, "top"])

        return edges

    def _prepare_polygons(self, lines):
        polygons = []
        polygon = []
        for i in lines:
            if "stroke" not in i:
                polygon.append(i)
            else:
                polygon.append(i)
                polygons.append(polygon)
                polygon = []
        return polygons

def hw2(args):
    fileio = FileIO(args.file)
    lines = fileio.read()

    # print(lines)

    transformer = Transformer(lines, args)
    new_lines = transformer.transform_lines()

    clipping = Clip(new_lines, args, transformer)
    # clipped_lines = clipping.cohen_sutherland_clipping()
    # print(clipped_lines)
    clipped_polygons = clipping.sutherland_hodgman_clipping()
    viewport_polygons = clipping.world_to_viewport(clipped_polygons)
    scanfill = clipping.scan_fill(viewport_polygons)
    # print(clipped_polygons)
    # print(viewport_polygons)

    # for i in viewport_polygons:
    #     for j in i:
    #         print(j)

    # fileio.write_ps(viewport_polygons, args)
    fileio.write_pbm(scanfill, args)

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("-f", "--file", type=str, default="hw3_split.ps")
    parser.add_argument("-s", "--scaling_factor", type=float, default=1.0)
    parser.add_argument("-r", "--ccr", type=int, default=0)
    parser.add_argument("-m", "--x_dim", type=int, default=0)
    parser.add_argument("-n", "--y_dim", type=int, default=0)

    parser.add_argument("-a", "--lower_boundx", type=int, default=0)
    parser.add_argument("-b", "--lower_boundy", type=int, default=0)
    parser.add_argument("-c", "--upper_boundx", type=int, default=250)
    parser.add_argument("-d", "--upper_boundy", type=int, default=250)

    parser.add_argument("-j", "--lb_viewportx", type=int, default=0)
    parser.add_argument("-k", "--lb_viewporty", type=int, default=0)
    parser.add_argument("-o", "--ub_viewportx", type=int, default=200)
    parser.add_argument("-p", "--ub_viewporty", type=int, default=200)

    args = parser.parse_args()

    hw2(args)

if __name__ == "__main__":
    main()