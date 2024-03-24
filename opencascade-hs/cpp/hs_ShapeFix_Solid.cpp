#include <Message_ProgressRange.hxx>
#include <ShapeFix_Solid.hxx>
#include "hs_ShapeFix_Solid.h"

ShapeFix_Solid * hs_new_ShapeFix_Solid_fromSolid(TopoDS_Solid * solid){
    return new ShapeFix_Solid(*solid);
}

void hs_delete_ShapeFix_Solid(ShapeFix_Solid * shapeFix){
    delete shapeFix;
}

bool hs_ShapeFix_Solid_perform(ShapeFix_Solid * shapeFix, Message_ProgressRange * progress){
    return shapeFix->Perform(*progress);
}

TopoDS_Shape * hs_ShapeFix_Solid_solid(ShapeFix_Solid * shapeFix){
    return new TopoDS_Shape(shapeFix->Solid());
}

bool hs_ShapeFix_Solid_status(ShapeFix_Solid * shapeFix, ShapeExtend_Status status){
    return shapeFix->Status(status);
}