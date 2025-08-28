import { Request, Response, NextFunction } from 'express';
declare global {
    namespace Express {
        interface Request {
            user?: {
                id: string;
                email?: string;
                [key: string]: any;
            };
        }
    }
}
export declare function authenticateToken(req: Request, res: Response, next: NextFunction): Promise<Response<any, Record<string, any>> | undefined>;
export declare function requirePremium(req: Request, res: Response, next: NextFunction): void;
export declare function validateResourceOwnership(resourceUserIdField?: string): (req: Request, res: Response, next: NextFunction) => Response<any, Record<string, any>> | undefined;
//# sourceMappingURL=auth.d.ts.map