import { Request, Response } from 'express';
export declare class MealsController {
    static createMeal(req: Request, res: Response): Promise<Response<any, Record<string, any>> | undefined>;
    static getMeals(req: Request, res: Response): Promise<Response<any, Record<string, any>> | undefined>;
    static getMeal(req: Request, res: Response): Promise<Response<any, Record<string, any>> | undefined>;
    static updateMeal(req: Request, res: Response): Promise<Response<any, Record<string, any>> | undefined>;
    static deleteMeal(req: Request, res: Response): Promise<Response<any, Record<string, any>> | undefined>;
    static getDailySummary(req: Request, res: Response): Promise<Response<any, Record<string, any>> | undefined>;
}
//# sourceMappingURL=meals.d.ts.map