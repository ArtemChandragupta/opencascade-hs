#include <gp_Dir2d.hxx>
#include "hs_gp_Dir2d.h"

gp_Dir2d * hs_new_gp_Dir2d(double x, double y) {
    return new gp_Dir2d(x, y);
}

void hs_delete_gp_Dir2d(gp_Dir2d* dir){
    delete dir;
}

double hs_gp_Dir2d_X(gp_Dir2d * pnt){
    return pnt->X();
}

double hs_gp_Dir2d_Y(gp_Dir2d * pnt){
    return pnt->Y();
}


void hs_gp_Dir2d_SetX(gp_Dir2d * pnt, double x){
    pnt->SetX(x);
}

void hs_gp_Dir2d_SetY(gp_Dir2d * pnt, double y){
    pnt->SetY(y);
}

bool hs_gp_Dir2d_IsEqual(gp_Dir2d * a, gp_Dir2d * b, double angularTolerance){
    return a->IsEqual(*b, angularTolerance);
}

bool hs_gp_Dir2d_IsNormal(gp_Dir2d * a, gp_Dir2d * b, double angularTolerance){
    return a->IsNormal(*b, angularTolerance);
}

bool hs_gp_Dir2d_IsOpposite(gp_Dir2d * a, gp_Dir2d * b, double angularTolerance){
    return a->IsOpposite(*b, angularTolerance);
}

bool hs_gp_Dir2d_IsParallel(gp_Dir2d * a, gp_Dir2d * b, double angularTolerance){
    return a->IsParallel(*b, angularTolerance);
}

double hs_gp_Dir2d_Angle(gp_Dir2d * a, gp_Dir2d * b){
    return a->Angle(*b);
}

double hs_gp_Dir2d_Crossed(gp_Dir2d * a, gp_Dir2d * b){
    return a->Crossed(*b);
}

double hs_gp_Dir2d_Dot(gp_Dir2d * a, gp_Dir2d * b){
    return a->Dot(*b);
}

void hs_gp_Dir2d_Reverse(gp_Dir2d* ax1){
    ax1->Reverse();
}

gp_Dir2d * hs_gp_Dir2d_Reversed(gp_Dir2d* ax1){
    return new gp_Dir2d(ax1->Reversed());
}

void hs_gp_Dir2d_Mirror(gp_Dir2d * theDir2d, gp_Dir2d * theAxis){
    theDir2d->Mirror(*theAxis);
}

gp_Dir2d * hs_gp_Dir2d_Mirrored(gp_Dir2d * theDir2d, gp_Dir2d * theAxis){
    return new gp_Dir2d(theDir2d->Mirrored(*theAxis));
}

void hs_gp_Dir2d_MirrorAboutAx2d(gp_Dir2d * theDir2d, gp_Ax2d * theAxis){
    theDir2d->Mirror(*theAxis);
}

gp_Dir2d * hs_gp_Dir2d_MirroredAboutAx2d(gp_Dir2d * theDir2d, gp_Ax2d * theAxis){
    return new gp_Dir2d(theDir2d->Mirrored(*theAxis));
}

void hs_gp_Dir2d_Rotate(gp_Dir2d * theDir2d, double amount){
    theDir2d->Rotate(amount);
}

gp_Dir2d * hs_gp_Dir2d_Rotated(gp_Dir2d * theDir2d, double amount){
    return new gp_Dir2d(theDir2d->Rotated(amount));
}

void hs_gp_Dir2d_Transform(gp_Dir2d * theDir2d, gp_Trsf2d * trsf){
    theDir2d->Transform(*trsf);
}

gp_Dir2d * hs_gp_Dir2d_Transformed(gp_Dir2d * theDir2d, gp_Trsf2d * trsf){
    return new gp_Dir2d(theDir2d->Transformed(*trsf));
}
