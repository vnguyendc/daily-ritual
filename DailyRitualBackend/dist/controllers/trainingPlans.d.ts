import { Request, Response } from 'express';
export declare class TrainingPlansController {
    static get(req: Request, res: Response): Promise<Response<any, Record<string, any>> | undefined>;
    static listInRange(req: Request, res: Response): Promise<Response<any, Record<string, any>> | undefined>;
    static list(req: Request, res: Response): Promise<Response<any, Record<string, any>> | undefined>;
    static create(req: Request, res: Response): Promise<Response<any, Record<string, any>> | undefined>;
    static update(req: Request, res: Response): Promise<Response<any, Record<string, any>> | undefined>;
    static remove(req: Request, res: Response): Promise<Response<any, Record<string, any>> | undefined>;
}
//# sourceMappingURL=trainingPlans.d.ts.map