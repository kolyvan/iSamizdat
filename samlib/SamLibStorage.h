//
//  SamLibStorage.h
//  samlib
//
//  Created by Kolyvan on 20.06.12.
//  Copyright (c) 2012 Konstantin Boukreev. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^EnumerateFolderBlock)(NSFileManager *fm, NSString *fullpath, NSDictionary *attr);

typedef struct {
    
    NSString * (*authorsPath)();
    NSString * (*textsPath)();    
    NSString * (*commentsPath)();
    NSString * (*namesPath)();    

    void (*enumerateFolder)(NSString *folder, EnumerateFolderBlock block);
    
    unsigned long long (*sizeOfTexts)();
    unsigned long long (*sizeOfComments)();
    unsigned long long (*sizeOfNames)();    
    
    void (*cleanupTexts)();
    void (*cleanupComments)();    
    void (*cleanupNames)();
    
    BOOL (*allowTexts)();
    BOOL (*allowComments)();            
    BOOL (*allowNames)();    
    
    void (*setAllowTexts)(BOOL);    
    void (*setAllowComments)(BOOL);    
    void (*setAllowNames)(BOOL);        

    id (*loadObject)(NSString *filepath, BOOL immutable);
    
    NSDictionary * (*loadDictionary)(NSString *filepath);
    NSDictionary * (*loadDictionaryEx)(NSString *filepath, BOOL immutable);
    
    BOOL (*saveObject)(id obj, NSString *filepath);
    BOOL (*saveDictionary)(NSDictionary *dict, NSString *filepath);    
    
    
} SamLibStorage_t;

extern SamLibStorage_t SamLibStorage;