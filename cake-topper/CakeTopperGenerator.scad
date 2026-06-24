Font="HarmonyOS Sans SC";
Text_1="Happy";
Text_2="Birthday";
Text_3="";
//Font size
Text_1_Size=30;
//Font size
Text_2_Size=30;
//Font size
Text_3_Size=30;
//Height offset (in mm) 
Text_1_Offset=17;
//Height offset (in mm) 
Text_2_Offset=0;
//Hidden
Text_3_Offset=(0);
//Number of extrusion layers
Text_1_Layers=4;
//Number of extrusion layers
Text_2_Layers=4;
//Number of extrusion layers
Text_3_Layers=4;
Text_Boldness=2.0;
Text_Spacing=1.00;
//(in mm)
Outline_thickness=3.0;
//Number of extrusion layers
Outline_Layers=8;
//Distance between post (in mm). 0 for single post. 
Post_Spacing=75;
//(in mm)
Post_Width=4;
//(in mm)
Post_Length=90;
//Additional support to connect loose text
Add_Support=false;
//(in mm)
Extrusion_Layer_Height=0.20;


//Private Variables
outlineExtrusion=Outline_Layers * Extrusion_Layer_Height;
textColor=str("red");
outlineColor=str("white");
$fn=100;

//Preparation
remap=[len(Text_3)>0&&len(Text_2)>0?0:-1,
       len(Text_2)>0?(len(Text_3)>0?1:0):len(Text_3)>0?0:-1,
       len(Text_3)>0?2:len(Text_2)>0?1:0];
echo(remap);
vText=[Text_1,Text_2,Text_3];
vSize=[Text_1_Size,Text_2_Size,Text_3_Size];
vLayer=[Text_1_Layers,Text_2_Layers,Text_3_Layers];
vOffset=[Text_1_Offset,Text_2_Offset,Text_3_Offset];

//echo(vText);
//echo(vSize);
//echo(vLayer);
//echo(vOffset);

union() {
    for (i=[0:len(vText)-1]) {
        let(idx=remap[i],text=vText[idx],size=vSize[idx],
                layer=vLayer[idx],y=height(i)) {
            //echo(str("remap:",i," > ",idx));
            //echo(str("text=",text));
            //echo(str("size=",size));
            //echo(str("layer=",layer));
            //echo(str("y=",y));
            
            if (idx>=0) {
                //Text
                color(textColor)
                translate([0,y,outlineExtrusion+0.0001]) {
                    linear_extrude(vLayer[idx]*Extrusion_Layer_Height)
                    offset(r=Text_Boldness) {
                    text(text=text, 
                        size=size,
                        font=Font,
                        spacing=Text_Spacing,
                        halign="center");
                    }
                }
                //Outline
                color(outlineColor)
                translate([0,y,0]) {
                    linear_extrude(outlineExtrusion)
                    offset(r=Text_Boldness+Outline_thickness) {
                        text(text=text, 
                            size=size, 
                            font=Font, 
                            spacing=Text_Spacing,
                            halign="center");
                    }
                }
            }
        }
    }

    if (Add_Support) {
        for (i=[0:len(vText)-1]) {
            //Horizontal support
            color(outlineColor)
            translate([-Post_Spacing/2,height(i)-Outline_thickness,0]) {
                cube([Post_Spacing,Outline_thickness,outlineExtrusion]);   
            }    
            for (m=[-1,1]) {
                //Vertical support
                color(outlineColor)
                translate([Post_Width/2+m*Post_Spacing/2,height(i),0]) {
                    rotate([0,0,180])
                    cube([Outline_thickness,height(i),outlineExtrusion]);   
                }
            }
        }
    }

    if (Post_Length > 0) {
        for (m=[-1,1]) {
            //Post
            color(outlineColor)
            translate([Post_Width/2+m*Post_Spacing/2,0,0]) {
                rotate([0,0,180])
                cube([Post_Width,Post_Length,outlineExtrusion]);   
            }
            //Post end
            color(outlineColor)
            translate([m*Post_Spacing/2,-Post_Length,0]) {
                cylinder(h=outlineExtrusion, r=Post_Width/2);   
            }
        }
    }
}

function height(i) = 
        i>=len(vText)-1 || remap[i] == -1
        ? 0 
        : vSize[remap[i+1]] + vOffset[remap[i]] + height(i+1);

