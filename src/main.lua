



--Project Title: Spur Gear differential without internal gears
--Group Number: 21
--Group Members: Jaykumar Patel
--Professor: Dr.-Ing. Stefan Scherbarth 
--Subject: Case Study Cyber Physical Production Systems using AM (Additive Manufacturing) (SS-2024)




function gear(z_l,m_t,alpha_t,h_a_coef,h_f_coef,f_r)
    local xy_points = {} --initialization of xy_points table to store xy coordinates of gear
    local z=z_l;
    local alpha_t_rad=alpha_t*math.pi/180 --pressure angle converted from deg to rad.

    local h_a = m_t * h_a_coef; -- Addendum
    local h_f = m_t * h_f_coef; -- Dedendum

    local d_p = m_t * z; -- Pitch diameter
    local r_p = d_p/2; --pitch radius

    local d_b = d_p * math.cos(alpha_t_rad); --Base diameter
    local r_b = d_b / 2; --base radius
    
    local d_a = d_p + 2*h_a; -- Tip diameter
    local r_a = d_a / 2; --tip radius

    local d_f = d_p - 2*h_f; -- Root diameter
    r_f = d_f / 2; --root radius

    local s_0 = m_t * (math.pi/2); -- tooth thickness at pitch circle considering profile shift = 0

    local psi_pitch = s_0/r_p -- Tooth thickness half angle 

    inv_alpha_t = math.tan(alpha_t_rad) - alpha_t_rad; -- involute function at pressure angle

    local d_TIF = math.sqrt(math.pow(d_p*math.sin(alpha_t_rad)- 2*(h_a-h_f*(1-math.sin(alpha_t_rad))),2) + d_b * d_b)
    -- True involute diameter
    local r_TIF = d_TIF/2; -- true involute radius

    local alpha_TIF = math.acos((d_p*math.cos(alpha_t_rad))/d_TIF); --pressure angle at True involute diameter

    local inv_alpha_TIF = math.tan(alpha_TIF) - alpha_TIF; -- Involute function at True involute diameter

    local s_ty = d_TIF * ((s_0/d_p)+inv_alpha_t - inv_alpha_TIF); --tooth thickness at TIF circle (considering profile shift = 0 )

    -----local Functions that are used in this fuction only -----
    --Function defining angle between corresponding radiuses
    local function involute_angle(r_1,r_2)
        return math.sqrt(((r_2 * r_2) -(r_1 *r_1))/(r_1 *r_1))
    end

    --Function for finding slope (y2 -y1/x2-x1)
    local function slope(coords)
        return ((coords[2].y - coords[1].y)/(coords[2].x - coords[1].x))
    end

    --Function for calculation points of involute curve
    local function tooth_involute(r_b, angle)                 
        return v(r_b*(math.sin(angle) - angle*math.cos(angle)), 
    			r_b*(math.cos(angle) + angle* math.sin(angle)))
    end

    --Function for mirroring involute points w.r.t y axies
    local function mirror_(points)
        return v(-points.x,points.y)
    end

    --Function to rotate points using the rotational matrix
    local function rotate_points(angle, coord)                                                                                    
        return v(math.cos(angle) * coord.x + math.sin(angle) * coord.y, math.cos(angle) * coord.y - math.sin(angle) * coord.x)
    end

    --Function for creating cirle
    local function circle(centre_point,r,th)
        return v(centre_point.x+ r*math.cos(th),centre_point.y+ r*math.sin(th))
    end
    

    local invo_angle = (s_0/r_p) + 2*inv_alpha_t -- To draw the involute between two circles w.r.t angle

    local start_angle = involute_angle(r_b,r_b) -- Eventually = 0
    local stop_angle = involute_angle(r_b,r_a)
    -- To start and stop involute between r_a and r_b (tip to base radius)
    
    --Fillet formed at the root area of gear with slope of the line and with f_r(fillet radius) and r_b.(end point from the tooth profile above the base circle has the same common tangent with the start point from the tooth profile below the base circle)
    --next step is to create parts under the base circle by finding the boundary of the same common tangent on the profile curve, that is, the position where the base circle curve intersects the profile curve.

    local n_points = 30; --for loop iteration
    local points = {} 
    -- finding point of involute to find fillet
    for i = 1,n_points do
        points[i] = tooth_involute(r_b,(start_angle + (stop_angle -start_angle) * i / n_points))
    end

    local m_s = slope(points) 
    --With the value of slope, the next step is to find the slope angle.
    local slope_angle = math.atan(m_s)

    local parellel_line = {}
    parellel_line[1] = v(points[1].x + f_r * math.cos(slope_angle + math.pi / 2),
                        points[1].y + f_r * math.sin(slope_angle + math.pi / 2)) 
    --A parallel line to the slope of line is formed so as to find the point to form the circle

    -- distence from parellel line to fillet radius centre
    local d = (parellel_line[1].y - m_s * parellel_line[1].x) / math.sqrt(m_s*m_s + 1)
    local th1 = math.asin(d/(f_r + r_b)) + slope_angle
    
    local fillet_center = v(0,0) --initialization of fillet centre variable
    local fillet_center = v((f_r + r_f) * math.cos(th1), (f_r + r_f) * math.sin(th1))
    local filler_start_angle = 2 * math.pi + math.atan(fillet_center.y / fillet_center.x)
    local fillet_stop_angle = 3 * math.pi / 2 + slope_angle
    

    --nested for loop for creating full gear profile including fillet
    for i=1, z do
        for j=1,n_points do -- for fillet
            xy_points[#xy_points+1] = rotate_points(2*math.pi*i/z,circle(fillet_center,f_r,(filler_start_angle +(fillet_stop_angle-filler_start_angle) * j / n_points)))
        end

        -- To start involute from form radius (r_TIF) and end at tip radius (r_a)
        start_angle = involute_angle(r_b,r_TIF)
        stop_angle = involute_angle(r_b,r_a)

        for j=1,n_points do -- for one side of the involute
            xy_points[#xy_points+1] = rotate_points(2*math.pi*i/z,tooth_involute(r_b, (start_angle +(stop_angle-start_angle) *j / n_points)))
        end

        -- now for the other side just mirroring involute and fillet
        for j=n_points,1,-1 do 
            xy_points[#xy_points+1] = rotate_points(2*math.pi*i/z,rotate_points(invo_angle,mirror_(tooth_involute(r_b,(start_angle +(stop_angle-start_angle) *j / n_points)))))    
        end
        for j=n_points,1,-1 do
            xy_points[#xy_points+1] = rotate_points(2*math.pi*i/z,rotate_points(invo_angle,mirror_(circle(fillet_center,f_r,(filler_start_angle +(fillet_stop_angle-filler_start_angle) * j / n_points)))))
        end
    end
    -- Adding first point to table for creating closed loop
    xy_points[#xy_points+1] = xy_points[1]
    return xy_points
end

--function to find center distance between two gears
function center_distance(z1,z2,m_t)
    return (m_t*(z1 + z2)/2) + j_n
end

--function to calculate angle of rotation for the second planetary set
function otherside_rotation_angle(z_s,z_p,m_t)
    --print("hallo")
    angle = 2*asin(center_distance(z_p,z_p,m_t)/(2*center_distance(z_s,z_p,m_t)))
    return angle
end


-------- Function for properlly extruding gear-----
--this function takes the following parameters 
--(z,m_t,alpha_t,h_a_coef,h_f_coef,f_r,b,bore_diameter,is_sun,is_left_side,_shaft_length)
--and returns the extruded gear for planet and sun gears acording to the parameters


function extrude_gear(z,m_t,alpha_t,h_a_coef,h_f_coef,f_r,b,bore_diameter,is_sun,is_left_side,_shaft_length)
    local gear_points = gear(z,m_t,alpha_t,h_a_coef,h_f_coef,f_r)
    local gear_extrude = linear_extrude(v(0,0,b),gear_points)
    local roof_cylinder = cylinder(r_f,b)
    local gear_extruded = rotate(-90,Z)*rotate(90/z+(inv_alpha_t*180/math.pi),Z)*union(gear_extrude , roof_cylinder)
    
    if (is_sun) then
        r_shaft_right = bore_diameter/2;
        r_shaft_left = r_shaft_right-2;
        if (is_left_side) then
            _shaft_length = 2*_shaft_length; --length of shaft for left sun gear is twice the length of shaft for right sun gear
            shaft = cylinder(r_shaft_left,_shaft_length)
            shaft = union(shaft,cylinder(r_shaft_left+1,spacing_bt_sun-b_sun-0.5))
            shaft_hole = translate(0,0,-b)*cylinder(r_shaft_left-2,2*_shaft_length)
        else
            shaft = cylinder(r_shaft_right,_shaft_length)
            shaft_hole = translate(0,0,-b)*cylinder(r_shaft_left*1.05,2*_shaft_length)
        end
        final_gear_extruded = difference(union(gear_extruded,translate(0,0,b)*shaft),shaft_hole)
        --print("if")
    else
        local bore = cylinder(bore_diameter/2,b)
        final_gear_extruded = difference(gear_extruded,bore)
        --print('else')
    end
    return final_gear_extruded
end


--function for generating and returning rotated planet gears (three)---
--this function takes the planet gear and returns three planet gears rotated by 120 degrees
--only one side of the planet gears 

function planet_gears_oneside(planet)
    local p_gear1 = rotate(0,Z)*translate(center_distance(z_sun,z_planet,m_t),0,0)*rotate(180,Z)*planet
    local p_gear2 = rotate(120,Z)*translate(center_distance(z_sun,z_planet,m_t),0,0)*rotate(180,Z)*planet
    local p_gear3 = rotate(240,Z)*translate(center_distance(z_sun,z_planet,m_t),0,0)*rotate(180,Z)*planet
    return p_gear1,p_gear2,p_gear3
end

---function for creating and extruding shaft for planet gear
function extrude_planet_shaft(spacing_bt_sun,b_sun,b_planet,tolerance,bore_diameter_planet,screw_diameter)
    shaft_length = spacing_bt_sun + b_sun + tolerance;
    --print(tostring(shaft_length))
    local spacer_length = b_planet*0.20 + b_sun;
    local spacer = cylinder(planet_shaft_radius+1,spacer_length)
    local hole = cylinder(screw_diameter/2,shaft_length)
    local shaft = difference(union(cylinder(planet_shaft_radius,shaft_length),spacer),hole)    
    return shaft
end

--function for calculating angular backlash for given gear in degrees
function angular_backlash(z)
    return 360/math.pi * j_n/(m_t*z)*cos(alpha_t)
end


--------setting up brushes for coloring parts-------
set_brush_color(100,1,0,0)
set_brush_color(101,1,1,0)
set_brush_color(102,0,0,1)
set_brush_color(103,0,1,0)
set_brush_color(104,0,28/255,142/255)

--------------Tweeks-------------


m_t = ui_numberBox("Module",2)
alpha_t = ui_numberBox("Pressure Angle(deg)",20)
z_sun = ui_numberBox("Number of teeth for Sun gear",30)
z_planet = ui_numberBox("Number of teeth for Planet gear",12)
h_a_coef = ui_scalar("Addedum Coefficient",1,0.5,1.5)
h_f_coef = ui_scalar("Dedendum coefficient",1.25,0.5,1.5) 
f_r = ui_scalar("fillet radius(mm)",0.2,0,m_t/2)
j_n = ui_scalar("Backlash(mm)",0.2,0.1,1)
b_sun = ui_numberBox("Width of the sun gear(mm)",5)
b_planet_min = 2*b_sun;
b_planet = ui_number("Width of the Planet gear(mm)",b_planet_min,b_planet_min,4*b_sun)
--animate_angle = ui_numberBox("animation angle",0)*10
modes = {{0,"Assembly"},{1,"Part"}}
mode = ui_radio("View Mode", modes)



---sun gear tooth number condition
--without this condition the planet gear pair will not mesh with the sun gears
if (z_sun % 3 ~= 0) then
    print("Please select the number of teeth for the sun gear as a multiple of 3.")
end




---- Adding Names of team members ----

f = font(Path .. "LiberationMono-Bold.ttf")

name_initials = f:str('J.A.O.R', 2.5) 
name_initials=scale(0.8,0.8,1)*name_initials
--name initials are added in carrier function
--emit(rotate(0,0,10)*scale(1,1,10) * name_initials)


---Some important perameters----
screw_diameter = 4; --diameter of screw
shaft_diameter_sun = z_sun*m_t*0.35; --diameter of shaft for sun gear (35% of the pitch diameter of sun gear)

if (z_planet*m_t*0.35 > screw_diameter) then    
    bore_diameter_planet = z_planet*m_t*0.35; 
    --if the caculated bore diameter is less than the screw diameter 
    --diameter of bore for planet gear (35% of the pitch diameter of planet gear)
else
    bore_diameter_planet = screw_diameter+4; 
    --if the bore diameter is less than the screw diameter then the bore diameter is set to screw diameter plus 4mm
end

bore_diameter_carrier = shaft_diameter_sun*1.03; --diameter of bore for carrier (3% more than the shaft diameter of sun gear)

b_carrier = 4; --width of carrier
spacing_bt_sun = b_planet*1.20; -- spacing between sun gears (20% more than the width of planet gear)
sun_shaft_length = 20; --length of right sun shaft (length of left sun shaft is twice the length of right sun shaft)
planet_shaft_radius = (bore_diameter_planet-bore_diameter_planet*0.02)/2; 
--radius of planet shaft (2% less than the bore diameter of planet gear)





--------------carrier----------------

space_bt_carrier = spacing_bt_sun+b_carrier+b_sun+1; --spacing between two carriers
--it is calculated by adding spacing between sun gears, width of sun gear and width of carrier
--and 1mm is added to compansae the extra 1mm length of the planet shafts

--function for creating carrier

function carrier()
    local thickness = b_carrier;
    local outer_boundry = cylinder(center_distance(z_sun,z_planet,m_t)+planet_shaft_radius+1,thickness)  
    local inner_boundry = cylinder(center_distance(z_sun,z_planet,m_t)-planet_shaft_radius-1,5)
    local ring = difference(outer_boundry,inner_boundry)
    
    local outer_ring_cutting = rotate(60+otherside_rotation_angle(z_sun,z_planet,m_t)/2,Z)*
                                translate(center_distance(z_sun,z_planet,m_t)/2,0,0)*
                                cube(center_distance(z_sun,z_planet,m_t)+4*planet_shaft_radius,((center_distance(z_sun,z_planet,m_t)+planet_shaft_radius+1)*(120-2*otherside_rotation_angle(z_sun,z_planet,m_t))*math.pi/180)-3,thickness)
    for i=1,3 do
        outer_ring_cutting = union(outer_ring_cutting,rotate(120*i,Z)*outer_ring_cutting)
    end
    local ring = difference(ring,outer_ring_cutting)
    local inner_and_outer_geometry_connector = rotate(otherside_rotation_angle(z_sun,z_planet,m_t)/2,Z)*translate(center_distance(z_sun,z_planet,m_t)/2,0,0)*cube(center_distance(z_sun,z_planet,m_t),10,thickness)
    for i=1,3 do
        inner_and_outer_geometry_connector = union(inner_and_outer_geometry_connector,rotate(120*i,Z)*inner_and_outer_geometry_connector)
    end
    
    local hole = translate(center_distance(z_sun,z_planet,m_t),0,0)*cylinder(screw_diameter/2,5)
    for i=1,3 do
        hole = union(hole,rotate(120*i,Z)*translate(center_distance(z_sun,z_planet,m_t),0,0)*cylinder(screw_diameter/2,thickness))
        hole = union(hole,rotate(120*i,Z)*rotate(otherside_rotation_angle(z_sun,z_planet,m_t),Z)*translate(center_distance(z_sun,z_planet,m_t),0,0)*cylinder(screw_diameter/2,thickness))
    end
    local center_geometry = cylinder(2*bore_diameter_carrier/2,thickness)
    local center_geometry = union(center_geometry,inner_and_outer_geometry_connector)
    local center_geometry = difference(center_geometry,cylinder(bore_diameter_carrier/2,5))
    
    local ring = union(ring,center_geometry)
    local ring = difference(ring,hole)
    local name_initials = rotate(otherside_rotation_angle(z_sun,z_planet,m_t)/2,Z)*scale(1,1,1)*rotate(60,Z)*translate(-45,-2.5,b_carrier-1)*name_initials
    local ring = difference(ring,name_initials)
    return ring
end

if (mode==0) then
    emit(carrier())
    emit(translate(0,0,space_bt_carrier)*carrier())
end

--------------  one side -----------------
is_sun = true;
is_left_side = true;
sun = extrude_gear(z_sun,m_t,alpha_t,h_a_coef,h_f_coef,f_r,b_sun,shaft_diameter_sun,is_sun,is_left_side,sun_shaft_length)
sun_gear_left = rotate(angular_backlash(z_sun),Z)*translate(0,0,b_carrier)*rotate(180/z_sun,Z)*sun

planet = extrude_gear(z_planet,m_t,alpha_t,h_a_coef,h_f_coef,f_r,b_planet,bore_diameter_planet)
planet_gear1,planet_gear2,planet_gear3 = planet_gears_oneside(rotate(-angular_backlash(z_planet),Z)*translate(0,0,b_carrier)*planet)

if (mode==0) then
    emit(sun_gear_left,1)
    
    emit(planet_gear1,101)
    emit(planet_gear2,101)
    emit(planet_gear3,101)
end

-------------- other side ---------------
is_sun = true;
is_left_side = false;
sun = extrude_gear(z_sun,m_t,alpha_t,h_a_coef,h_f_coef,f_r,b_sun,shaft_diameter_sun,is_sun,is_left_side,sun_shaft_length)
sun_gear_right = rotate(-angular_backlash(z_sun),Z)*translate(0,0,b_carrier)*rotate(180/z_sun,Z)*sun
planet_gear = rotate(180/z_planet,Z)*planet
planet_gear1,planet_gear2,planet_gear3 = planet_gears_oneside(rotate(angular_backlash(z_planet),Z)*translate(0,0,b_carrier)*planet_gear)
if (mode==0) then
    emit(rotate(otherside_rotation_angle(z_sun,z_planet,m_t),Z)*rotate((-z_planet/z_sun)*(180/z_planet),Z)*translate(0,0,spacing_bt_sun)*sun_gear_right,100)

    emit(rotate(otherside_rotation_angle(z_sun,z_planet,m_t),Z)*translate(0,0,(spacing_bt_sun+b_sun)-b_planet)*planet_gear1,101)
    emit(rotate(otherside_rotation_angle(z_sun,z_planet,m_t),Z)*translate(0,0,(spacing_bt_sun+b_sun)-b_planet)*planet_gear2,101)
    emit(rotate(otherside_rotation_angle(z_sun,z_planet,m_t),Z)*translate(0,0,(spacing_bt_sun+b_sun)-b_planet)*planet_gear3,101)
end



------ shaft for planet gears---
tolerance = 1; --tolerance between planet gears and carrier
--it is there to ensure free movement of planet gears

planet_shaft = extrude_planet_shaft(spacing_bt_sun,b_sun,b_planet,tolerance,bore_diameter_planet,screw_diameter)
shaft_oneside = rotate(otherside_rotation_angle(z_sun,z_planet,m_t),Z)*translate(center_distance(z_sun,z_planet,m_t),0,b_carrier)*planet_shaft;
shaft_otherside = translate(0,0,shaft_length+b_carrier)*rotate(180,X)*translate(center_distance(z_sun,z_planet,m_t),0,0)*planet_shaft;
all_planet_shafts = union(shaft_oneside,shaft_otherside);
for i=1,2 do
    local shaft_oneside = rotate(120*i,Z)*rotate(otherside_rotation_angle(z_sun,z_planet,m_t),Z)*translate(center_distance(z_sun,z_planet,m_t),0,b_carrier)*planet_shaft;
    local shaft_otherside = rotate(120*i,Z)*translate(0,0,shaft_length+b_carrier)*rotate(180,X)*translate(center_distance(z_sun,z_planet,m_t),0,0)*planet_shaft;
    all_planet_shafts = union(all_planet_shafts,union(shaft_oneside,shaft_otherside))
end 

if (mode==0) then
    emit(all_planet_shafts,103)
end



------ Wheels -------
--function for creating wheel
function create_wheel(r_wheel,r_hole)
    local wheel = cylinder(r_wheel,b_wheel)
    
    local n = 10
    local cc = cube(4*bore_diameter_carrier/10,bore_diameter_carrier/8,b_wheel)
    local design = translate(r_wheel-screw_diameter,0,0)*cc;
    for i=1,n-1 do 
        design = union(design,rotate(360*i/n,Z)*translate(r_wheel-screw_diameter,0,0)*cc)        
    end
    local wheel = difference(wheel,design)
    local connector = translate(0,0,-4)*cylinder(r_hole+2,4)
    local connector = difference(connector,translate(0,0,-2)*rotate(90,X)*cylinder(1,bore_diameter_carrier))
    local wheel = union(wheel,connector)
    local hole = translate(0,0,-4)*cylinder(r_hole,b_wheel+4)
    local wheel = difference(wheel,hole)
    return wheel   
end
b_wheel = 3; --thickness of wheel
r_wheel_right = 1.25*bore_diameter_carrier; --radius of right wheel is 1.25 times the bore diameter of carrier
r_wheel_left = 1.25*bore_diameter_carrier*0.80; --radius of left wheel is 1.25 times the bore diameter of carrier and 20% reduction in radius (20% reduction in radius is for clear visibility of the both the wheels)
wheel_right = translate(0,0,sun_shaft_length+b_sun+b_carrier+spacing_bt_sun-b_wheel)*create_wheel(r_wheel_right,r_shaft_right*1.02)
wheel_left = translate(0,0,2*sun_shaft_length+b_sun+b_carrier-b_wheel)*create_wheel(r_wheel_left,r_shaft_left*1.02)
if (mode==0) then
    emit(wheel_left,5)
    emit(wheel_right,5)
end





-----mounting plate and shaft-----
r_mounting_plate = 25     --radius of mounting plate
b_mounting_plate = 5       --thickness of mounting plate
clearance_for_shaft = 2    --clearance between carrier and mounting plate
b_end_plate = 2              --thickness of end plate
l_shaft = 2*sun_shaft_length+b_carrier+clearance_for_shaft+1+b_sun  
--in this case the length of shaft is equal to the length of left sun shaft + the length of carrier + face width of sun gear +
--the clearance between carrier and mounting plate an +1mm for the clearance between mounting plate and end plate
r_shaft = (r_shaft_left-2)*0.98 --radius of shaft is equal to the radius of left sun shaft minus 2mm and 2% reduction in radius



--creating mounting plate
mounting_plate = cylinder(r_mounting_plate,b_mounting_plate)
hole_for_mounting = translate(r_mounting_plate/1.5,0,0)*cylinder(screw_diameter/2,b_mounting_plate)
hole_for_mounting = union(hole_for_mounting,rotate(120,Z)*hole_for_mounting)
hole_for_mounting = union(hole_for_mounting,rotate(240,Z)*hole_for_mounting)

mounting_plate = translate(0,0,-b_mounting_plate-clearance_for_shaft)*difference(mounting_plate,hole_for_mounting)


--creating shaft
shaft = cylinder(r_shaft,l_shaft)
spacer_in_shaft = cylinder(r_shaft_right,b_carrier+clearance_for_shaft)
shaft = union(shaft,spacer_in_shaft)
shaft = translate(0,0,-clearance_for_shaft)*difference(shaft,translate(0,0,l_shaft-20)*cylinder(2,20))
--hole for screwing the mounting plate to the shaft (4mm diameter and 20mm depth)


--union of mounting plate and shaft
mounting_plate_and_shaft = union(mounting_plate,shaft)

--emitting mounting plate and shaft
if (mode==0) then
    emit(mounting_plate_and_shaft,102)
end

--end plate for shaft (end plate is used to hold gearBox in place)
--the radius of end plate is equal to the radius of shaft of the left sun gear
--the hole in the end plate is for screwing the end plate to the mounting plate shaft
end_plate = cylinder(r_shaft_left,b_end_plate)
end_plate = translate(0,0,l_shaft-clearance_for_shaft)*end_plate
end_plate = difference(end_plate,translate(0,0,l_shaft-clearance_for_shaft)*cylinder(2,20)) 
--hole for screwing the end plate to the mounting plate shaft (4mm diameter and 20mm depth) 

--emitting end plate
if (mode==0) then
    emit(end_plate,104)
end


------individual Part view------
--for generating individual parts of the gear box for STL file or getting G-code for 3d printing

part_list ={"Sun Gear (Right Side)", --0
            "Sun Gear (Left Side)",  --1
            "Planet Gear", --2
            "Planet shaft", --3
            "carrier", --4
            "Wheel (Right Side)",   --5
            "Wheel (Left Side)" ,   --6
            "Mounting Plate and Shaft", --7
            "end plate for Mounting Shaft", --8
        }


if (mode==1) then
    Select_Part = ui_combo("Select Part", part_list)
    if (Select_Part == 0) then
        emit(sun_gear_right,100)
    elseif (Select_Part == 1) then
        emit(sun_gear_left,1)
    elseif (Select_Part == 2) then
        emit(planet_gear1,101)
    elseif (Select_Part == 3) then
        emit(planet_shaft,103)
    elseif (Select_Part == 4) then
        emit(carrier())
    elseif (Select_Part == 5) then
        emit(rotate(180,X)*wheel_right,5)
    elseif (Select_Part == 6) then
        emit(rotate(180,X)*wheel_left,5)
    elseif (Select_Part == 7) then
        emit(mounting_plate_and_shaft,102)
    elseif (Select_Part == 8) then
        emit(end_plate,104)
    end
end