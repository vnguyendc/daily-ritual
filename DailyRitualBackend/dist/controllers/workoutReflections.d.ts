import { Request, Response } from 'express';
export declare class WorkoutReflectionsController {
    static createWorkoutReflection(req: Request, res: Response): Promise<Response<any, Record<string, any>> | undefined>;
    static getWorkoutReflections(req: Request, res: Response): Promise<Response<any, Record<string, any>> | undefined>;
    static getWorkoutReflection(req: Request, res: Response): Promise<Response<any, Record<string, any>> | undefined>;
    static updateWorkoutReflection(req: Request, res: Response): Promise<Response<any, Record<string, any>> | undefined>;
    static deleteWorkoutReflection(req: Request, res: Response): Promise<Response<any, Record<string, any>> | undefined>;
    static getWorkoutStats(req: Request, res: Response): Promise<Response<any, Record<string, any>> | undefined>;
}
//# sourceMappingURL=workoutReflections.d.ts.map